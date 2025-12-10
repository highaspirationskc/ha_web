class CommunityServiceRecord < ApplicationRecord
  belongs_to :mentee

  validates :event, presence: true
  validates :event_date, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0 }

  scope :approved, -> { where(approved: true) }
  scope :denied, -> { where(approved: false) }
end
