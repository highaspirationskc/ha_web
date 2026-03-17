class SeasEvaluation < ApplicationRecord
  belongs_to :mentee
  belongs_to :reviewer, class_name: "User", optional: true
  has_many :seas_responses, dependent: :destroy

  validates :token, uniqueness: true, allow_nil: true
  validates :status, presence: true, inclusion: { in: %w[pending in_progress submitted in_review reviewed] }
  validates :evaluation_year, presence: true

  before_validation :set_defaults, on: :create
  before_create :generate_token
  before_create :set_token_expiry

  scope :recent, -> { order(created_at: :desc) }

  def expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def completed?
    status.in?(%w[submitted in_review reviewed])
  end

  def reviewable?
    status.in?(%w[submitted in_review])
  end

  def final_total_score
    seas_responses.sum { |r| r.final_score }
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_token_expiry
    self.token_expires_at = 90.days.from_now
  end

  def set_defaults
    self.evaluation_year ||= Date.current.year
    self.sent_at = Time.current
  end
end
