class DashboardController < AuthenticatedController
  def index
    @current_season = Current.season
    @season_date_range = current_season_date_range

    # Calculate team standings using selected season's date range
    @team_standings = Team.all.map do |team|
      {
        team: team,
        points: team.total_points(@season_date_range),
        hours: team.total_community_service_hours(@season_date_range),
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

      # Get top mentees by community service hours for the season
      @top_service_hours_mentees = mentees.map do |mentee|
        {
          user: mentee.user,
          hours: mentee.total_community_service_hours(@season_date_range)
        }
      end.select { |m| m[:hours] > 0 }
        .sort_by { |m| -m[:hours] }
        .take(5)
    else
      @top_season_mentees = []
      @top_service_hours_mentees = []
    end
  end
end
