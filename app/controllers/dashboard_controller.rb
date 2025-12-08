class DashboardController < AuthenticatedController
  def index
    @current_season = OlympicSeason.current_season

    # Calculate team standings
    @team_standings = Team.all.map do |team|
      {
        team: team,
        points: team.total_points,
        member_count: team.mentees.count
      }
    end.sort_by { |standing| -standing[:points] }

    # Get top mentees for the season
    if @current_season
      season_service = OlympicSeasonService.new(@current_season)
      season_range = season_service.date_range_from_reference_date

      # Get all users who are mentees
      mentee_users = User.joins(:mentee)

      @top_season_mentees = mentee_users.map do |user|
        {
          user: user,
          points: user.total_points(season_range)
        }
      end.select { |m| m[:points] > 0 }
        .sort_by { |m| -m[:points] }
        .take(5)

      # Get top mentees for the current week
      week_start = Date.current.beginning_of_week
      week_end = Date.current.end_of_week
      week_range = week_start..week_end

      @top_week_mentees = mentee_users.map do |user|
        {
          user: user,
          points: user.total_points(week_range)
        }
      end.select { |m| m[:points] > 0 }
        .sort_by { |m| -m[:points] }
        .take(5)
    else
      @top_season_mentees = []
      @top_week_mentees = []
    end
  end
end
