class User < ApplicationRecord
  has_secure_password

  has_many :tokens, dependent: :destroy

  # Team relationship
  belongs_to :team, optional: true

  # Family member associations (parent-child relationships)
  has_many :family_members, dependent: :destroy
  has_many :reverse_family_members, class_name: "FamilyMember", foreign_key: :related_user_id, dependent: :destroy

  # Event associations
  has_many :created_events, class_name: "Event", foreign_key: :created_by_id, dependent: :nullify
  has_many :event_logs, dependent: :destroy

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

  # Parent-child relationships (via FamilyMember)
  def children
    return User.none unless parent?
    User.where(id: family_members.where(relationship_type: :parent).select(:related_user_id))
  end

  def parents
    return User.none unless mentee?
    User.where(id: reverse_family_members.where(relationship_type: :parent).select(:user_id))
  end

  # Team-based access (for mentors/volunteers to see mentees on their team)
  def team_mentees
    return User.none unless (mentor? || volunteer?) && team_id
    User.where(team_id: team_id, role: :mentee)
  end

  # Permission check - can this user manage another user?
  def can_manage?(other_user)
    return true if self == other_user
    return true if admin? || staff?
    return true if (mentor? || volunteer?) && team_id && other_user.team_id == team_id
    return true if parent? && children.exists?(other_user.id)
    false
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
