class Team < ApplicationRecord
  has_many :users, dependent: :nullify
  alias_method :members, :users
  has_many :mentees, -> { where(role: :mentee) }, class_name: "User"
  has_many :parents, -> { where(role: :parent) }, class_name: "User"
  has_many :mentors, -> { where(role: :mentor) }, class_name: "User"
  has_many :event_logs, through: :users

  enum :color, { blue: 0, green: 1, yellow: 2, red: 3 }

  validates :name, presence: true, uniqueness: true
  validates :color, presence: true

  # Calculate total points for all users on this team for a given date range
  # If no date_range is provided, calculates for the current Olympic season
  def total_points(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    EventLog.joins(:user, :event)
            .where(users: { team_id: id })
            .where(events: { event_date: date_range })
            .sum(:points_awarded)
  end

  private

  def current_season_date_range
    current_season = OlympicSeason.current_season
    return nil unless current_season

    OlympicSeasonService.new(current_season).date_range_from_reference_date
  end
end
