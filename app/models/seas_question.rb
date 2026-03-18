class SeasQuestion < ApplicationRecord
  belongs_to :seas_domain
  has_many :seas_responses, dependent: :destroy

  validates :text, presence: true
  validates :position, presence: true, uniqueness: { scope: :seas_domain_id }
end
