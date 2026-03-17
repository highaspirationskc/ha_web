class SeasQuestion < ApplicationRecord
  belongs_to :seas_domain

  validates :text, presence: true
  validates :position, presence: true, uniqueness: { scope: :seas_domain_id }
end
