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
  before_create :snapshot_questionnaire

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

  def parsed_snapshot
    questionnaire_snapshot.present? ? JSON.parse(questionnaire_snapshot) : nil
  end

  def update_snapshot_with_scores!
    snapshot = parsed_snapshot
    return unless snapshot

    responses_by_question = seas_responses.index_by(&:seas_question_id)

    snapshot["domains"].each do |domain|
      domain["questions"].each do |question|
        response = responses_by_question[question["id"]]
        question["score"] = response&.score
      end
    end

    update_column(:questionnaire_snapshot, snapshot.to_json)
  end

  def update_snapshot_with_review_data!
    snapshot = parsed_snapshot
    return unless snapshot

    responses_by_question = seas_responses.index_by(&:seas_question_id)

    snapshot["domains"].each do |domain|
      domain["questions"].each do |question|
        response = responses_by_question[question["id"]]
        next unless response&.reviewed?

        question["review_action"] = response.review_action
        question["adjusted_score"] = response.adjusted_score
        question["feedback"] = response.feedback
      end
    end

    update_column(:questionnaire_snapshot, snapshot.to_json)
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

  def snapshot_questionnaire
    domains = SeasDomain.includes(:seas_questions).order(:position).map do |domain|
      {
        id: domain.id,
        name: domain.name,
        description: domain.description,
        position: domain.position,
        questions: domain.seas_questions.order(:position).map do |question|
          { id: question.id, text: question.text, position: question.position }
        end
      }
    end

    all_timestamps = SeasDomain.pluck(:updated_at) + SeasQuestion.pluck(:updated_at)
    version_timestamp = all_timestamps.max&.iso8601 || Time.current.iso8601

    self.questionnaire_snapshot = {
      version_timestamp: version_timestamp,
      domains: domains
    }.to_json
  end
end
