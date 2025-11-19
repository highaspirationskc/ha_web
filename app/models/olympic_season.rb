class OlympicSeason < ApplicationRecord
  validates :name, presence: true
  validates :start_month, presence: true
  validates :start_day, presence: true
  validates :end_month, presence: true
  validates :end_day, presence: true
end
