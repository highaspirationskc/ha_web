class User < ApplicationRecord
  has_secure_password

  has_many :tokens, dependent: :destroy

  # TODO: Change default role logic - currently defaulting to admin for development
  enum :role, {
    volunteer: 0,
    mentor: 1,
    mentee: 2,
    parent: 3,
    staff: 4,
    admin: 5
  }

  # Email validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Password validations
  validates :password, length: { minimum: 8 }, if: :password_required?
  validate :password_complexity, if: :password_required?

  before_create :generate_confirmation_token

  # Normalize email to lowercase
  before_save :normalize_email

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
end
