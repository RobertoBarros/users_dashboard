require "csv"

class UserImport < ApplicationRecord
  class InvalidCsvError < StandardError; end

  belongs_to :admin, class_name: "User"
  has_one_attached :file

  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }, validate: true

  scope :active, -> { where(status: %w[pending processing]) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  validate :csv_file
  after_create_commit :enqueue_import
  after_update_commit :broadcast_refresh_later

  def processed_count
    imported_count + failed_count
  end

  def prepare!
    data = parsed_rows
    with_lock do
      return [] if completed?

      update!(total_count: data.size, status: :processing, error_message: nil)
    end
    data
  end

  def import_user!(position, full_name, email_address)
    # Password hashing happens before the shared lock so jobs can do it in parallel.
    user = User.new(full_name: full_name, email_address: email_address, password: SecureRandom.base58(32))

    with_lock do
      return if results.key?(position.to_s)

      saved = begin
        User.transaction(requires_new: true) { user.save }
      rescue ActiveRecord::RecordNotUnique
        user.errors.add(:email_address, :taken)
        false
      end

      results[position.to_s] = {
        "position" => position, "full_name" => full_name, "email_address" => email_address,
        "status" => saved ? "imported" : "failed", "error_message" => user.errors.full_messages.join(", ").presence
      }
      saved ? self.imported_count += 1 : self.failed_count += 1
      if processed_count == total_count
        self.status = :completed
        self.error_message = nil
      end
      save!
    end
  end

  private
    def csv_file
      if !file.attached?
        errors.add(:file, "must be selected")
      elsif file.filename.extension.downcase != "csv"
        errors.add(:file, "must be a CSV file")
      elsif file.byte_size > 5.megabytes
        errors.add(:file, "must be smaller than 5 MB")
      end
    end

    def parsed_rows
      source = file.download.force_encoding(Encoding::UTF_8).delete_prefix("\uFEFF")
      raise InvalidCsvError, "The CSV must use UTF-8 encoding." unless source.valid_encoding? && !source.include?("\0")

      data = [ ",", ";", "\t" ].lazy.filter_map do |separator|
        CSV.parse(source, col_sep: separator, skip_blanks: true).reject { |row| row.all?(&:blank?) }
      rescue CSV::MalformedCSVError
        nil
      end.find { |table| table.any? && table.all? { |row| row.size == 2 } }
      raise InvalidCsvError, "Upload a CSV with exactly two columns: name and email." unless data

      headers = data.first.map { |value| value.to_s.strip.downcase }
      email_headers = %w[email e-mail email_address]
      name_headers = [ "name", "full_name", "full name", "nome" ]
      header_email = headers.index { |value| email_headers.include?(value) }
      has_header = header_email && name_headers.include?(headers[1 - header_email])
      data.shift if has_header
      raise InvalidCsvError, "The CSV has no users to import." if data.empty?

      scores = 2.times.map do |column|
        data.count { |row| URI::MailTo::EMAIL_REGEXP.match?(row[column].to_s.strip) }
      end
      email_column = if has_header
        header_email
      elsif scores.max.positive? && scores.uniq.size == 2
        scores.index(scores.max)
      end
      raise InvalidCsvError, "Could not identify the email column. Add name and email headers." unless email_column

      data.map { |row| [ row[1 - email_column].to_s.strip, row[email_column].to_s.strip ] }
    end

    def enqueue_import
      UserImports::ProcessCsvJob.perform_later(self)
    end
end
