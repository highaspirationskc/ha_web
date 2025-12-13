class User < ApplicationRecord
  has_secure_password

  has_many :tokens, dependent: :destroy
  has_many :user_devices, dependent: :destroy
  belongs_to :avatar, class_name: "Medium", optional: true

  # Role profiles
  has_one :mentor, dependent: :destroy
  has_one :mentee, dependent: :destroy
  has_one :guardian, dependent: :destroy
  has_one :staff, dependent: :destroy
  has_one :volunteer, dependent: :destroy

  # Event associations
  has_many :created_events, class_name: "Event", foreign_key: :created_by_id, dependent: :nullify
  has_many :event_logs, dependent: :destroy

  # Message associations
  has_many :sent_messages, class_name: "Message", foreign_key: :author_id, dependent: :destroy
  has_many :message_recipients, foreign_key: :recipient_id, dependent: :destroy
  has_many :received_messages, through: :message_recipients, source: :message

  # Media associations
  has_many :uploaded_media, class_name: "Medium", foreign_key: :uploaded_by_id, dependent: :destroy

  # Email validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Password validations
  validates :password, length: { minimum: 8 }, if: :password_required?
  validate :password_complexity, if: :password_required?

  before_create :generate_confirmation_token
  after_destroy :cleanup_avatar_medium

  # Normalize email to lowercase
  before_save :normalize_email

  # Role detection helper
  def role_name
    return "Admin" if staff&.admin?
    return "Staff" if staff.present?
    return "Mentor" if mentor.present?
    return "Mentee" if mentee.present?
    return "Guardian" if guardian.present?
    return "Volunteer" if volunteer.present?
    "User"
  end

  # Role check methods for authorization
  def admin?
    staff&.admin? || false
  end

  def staff?
    staff.present?
  end

  def mentor?
    mentor.present?
  end

  def mentee?
    mentee.present?
  end

  def guardian?
    guardian.present?
  end

  def volunteer?
    volunteer.present?
  end

  # Check if user can login to the application
  # Staff, mentors, mentees, and guardians can login
  def can_login?
    staff? || mentor? || mentee? || guardian?
  end

  # Authorization helper - delegates to Authorization service
  def can?(action, resource, target = nil)
    Authorization.can?(self, action, resource, target)
  end

  def can_access?(nav_item)
    Authorization.can_access?(self, nav_item)
  end

  def allowed_navigation
    Authorization.navigation_for(self)
  end

  # Count unread message threads
  def unread_message_count
    unread_message_ids = message_recipients.unread.pluck(:message_id)
    return 0 if unread_message_ids.empty?

    unread_messages = Message.where(id: unread_message_ids)
    root_ids = unread_messages.map { |m| m.parent_id || m.id }.uniq
    root_ids.count
  end

  # Activation methods
  def activate!
    update(active: true, confirmation_token: nil, confirmation_sent_at: nil)
  end

  def deactivate!
    update(active: false)
  end

  def send_confirmation_email
    UserMailer.confirmation_email(self).deliver_later
  end

  def request_password_reset!
    generate_confirmation_token
    save!
    UserMailer.password_reset_email(self).deliver_later
  end

  def confirmation_token_expired?
    return true if confirmation_sent_at.nil?
    confirmation_sent_at < 24.hours.ago
  end

  def clear_confirmation_token!
    update!(confirmation_token: nil, confirmation_sent_at: nil)
  end

  private

  def password_required?
    password_digest.nil? || password.present?
  end

  def password_complexity
    return if password.blank?

    unless password.match?(/[A-Z]/)
      errors.add :password, "must include at least one uppercase letter"
    end

    unless password.match?(/[0-9]/)
      errors.add :password, "must include at least one number"
    end

    unless password.match?(/[^A-Za-z0-9]/)
      errors.add :password, "must include at least one special character"
    end
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
    self.confirmation_sent_at = Time.current
  end

  def cleanup_avatar_medium
    return unless avatar&.single_use?

    begin
      CloudflareImagesService.delete(avatar.cloudflare_id)
    rescue CloudflareImagesService::DeleteError => e
      Rails.logger.warn("Failed to delete avatar from Cloudflare: #{e.message}")
    end
    avatar.destroy
  end
end
