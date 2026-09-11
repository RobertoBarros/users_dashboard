class User < ApplicationRecord
  has_one_attached :avatar

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_imports, foreign_key: :admin_id, dependent: :destroy

  enum :role, { user: "user", admin: "admin" }, validate: true

  validate :avatar_type

  validates :full_name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  broadcasts_refreshes_to ->(user) { "admin_dashboard" }
  after_update_commit -> { broadcast_refresh_later_to self, :profile }

  private
    def avatar_type
      return unless avatar.attached?

      if !%w[image/jpeg image/png image/gif image/webp].include?(avatar.content_type)
        errors.add(:avatar, "must be a JPEG, PNG, GIF, or WebP image")
      end
    end
end
