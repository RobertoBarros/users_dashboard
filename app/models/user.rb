class User < ApplicationRecord
  has_one_attached :avatar

  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { user: "user", admin: "admin" }, validate: true

  validate :avatar_presence_and_type

  validates :full_name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_commit :broadcast_dashboard_statistics,
    if: -> { previously_new_record? || destroyed? || saved_change_to_role? }

  private
    def broadcast_dashboard_statistics
      Turbo::StreamsChannel.broadcast_replace_to "admin_dashboard",
        target: "user_statistics", partial: "admin/dashboards/user_statistics"
    end

    def avatar_presence_and_type
      if !avatar.attached?
        errors.add(:avatar, "is required")
      elsif !%w[image/jpeg image/png image/gif image/webp].include?(avatar.content_type)
        errors.add(:avatar, "must be a JPEG, PNG, GIF, or WebP image")
      end
    end
end
