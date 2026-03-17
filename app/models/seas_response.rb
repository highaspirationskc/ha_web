class SeasResponse < ApplicationRecord
  belongs_to :seas_evaluation
  belongs_to :seas_question

  validates :score, presence: true, inclusion: { in: 0..3 }
  validates :seas_question_id, uniqueness: { scope: :seas_evaluation_id }
  validates :review_action, inclusion: { in: %w[confirmed adjusted] }, allow_nil: true
  validates :adjusted_score, inclusion: { in: 0..3 }, allow_nil: true

  def final_score
    adjusted_score || score
  end

  def reviewed?
    review_action.present?
  end
end
