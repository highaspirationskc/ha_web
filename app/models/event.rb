class Event < ApplicationRecord
  belongs_to :event_type
  belongs_to :created_by, class_name: "User"
  has_many :event_logs, dependent: :destroy
  has_many :users, through: :event_logs

  validates :name, presence: true
  validates :event_date, presence: true

  def olympic_season
    # Find which season this event_date falls into
    # (logic: check if event_date.month/day is within any season's start/end)
    return nil unless event_date

    OlympicSeason.all.find do |season|
      date_in_season?(event_date, season)
    end
  end

  private

  def date_in_season?(date, season)
    month = date.month
    day = date.day

    # Handle seasons that span across year boundary (e.g., Dec-Jan)
    if season.start_month <= season.end_month
      # Season within same year (e.g., March to August)
      (month > season.start_month || (month == season.start_month && day >= season.start_day)) &&
        (month < season.end_month || (month == season.end_month && day <= season.end_day))
    else
      # Season spans year boundary (e.g., November to February)
      (month > season.start_month || (month == season.start_month && day >= season.start_day)) ||
        (month < season.end_month || (month == season.end_month && day <= season.end_day))
    end
  end
end
