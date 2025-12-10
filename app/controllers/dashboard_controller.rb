class DashboardController < AuthenticatedController
  def index
    @current_season = Current.season
    @season_date_range = current_season_date_range

    # Calculate team standings using selected season's date range
    @team_standings = Team.all.map do |team|
      {
        team: team,
        points: team.total_points(@season_date_range),
        member_count: team.mentees.count
      }
    end.sort_by { |standing| -standing[:points] }

    # Get top mentees for the season
    if @current_season && @season_date_range
      mentees = Mentee.includes(:user)

      @top_season_mentees = mentees.map do |mentee|
        {
          user: mentee.user,
          points: mentee.total_points(@season_date_range)
        }
      end.select { |m| m[:points] > 0 }
        .sort_by { |m| -m[:points] }
        .take(5)

      # Get top mentees for the current week (always actual current week)
      week_start = Date.current.beginning_of_week
      week_end = Date.current.end_of_week
      week_range = week_start..week_end

      @top_week_mentees = mentees.map do |mentee|
        {
          user: mentee.user,
          points: mentee.total_points(week_range)
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
