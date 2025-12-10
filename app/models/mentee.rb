class Mentee < ApplicationRecord
  belongs_to :user
  belongs_to :mentor, optional: true
  belongs_to :team, optional: true

  has_many :family_members, dependent: :destroy
  has_many :guardians, through: :family_members
  has_many :community_service_records, dependent: :destroy

  # Calculate total points for a given date range
  # If no date_range is provided, calculates for the current Olympic season
  def total_points(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    user.event_logs.joins(:event)
        .where(events: { event_date: date_range })
        .sum(:points_awarded)
  end

  # Calculate total approved community service hours for a given date range
  def total_community_service_hours(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    community_service_records
      .approved
      .where(event_date: date_range)
      .sum(:hours)
  end

  private

  def current_season_date_range
    current_season = OlympicSeason.current_season
    return nil unless current_season

    OlympicSeasonService.new(current_season).date_range_from_reference_date
  end
end
