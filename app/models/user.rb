class User < ApplicationRecord
  has_secure_password

  has_many :tokens, dependent: :destroy

  # Role profiles
  has_one :mentor, dependent: :destroy
  has_one :mentee, dependent: :destroy
  has_one :guardian, dependent: :destroy
  has_one :staff, dependent: :destroy
  has_one :volunteer, dependent: :destroy

  # Event associations
  has_many :created_events, class_name: "Event", foreign_key: :created_by_id, dependent: :nullify
  has_many :event_logs, dependent: :destroy

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
  # Only staff (including admins) and mentors can login
  def can_login?
    staff? || mentor?
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

  # Calculate total points for a given date range
  # If no date_range is provided, calculates for the current Olympic season
  def total_points(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    event_logs.joins(:event)
              .where(events: { event_date: date_range })
              .sum(:points_awarded)
  end

  private

  def current_season_date_range
    current_season = OlympicSeason.current_season
    return nil unless current_season

    OlympicSeasonService.new(current_season).date_range_from_reference_date
  end

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
