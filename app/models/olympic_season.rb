class OlympicSeason < ApplicationRecord
  has_many :events, dependent: :destroy

  validates :name, presence: true
  validates :start_month, presence: true
  validates :start_day, presence: true
  validates :end_month, presence: true
  validates :end_day, presence: true
end
