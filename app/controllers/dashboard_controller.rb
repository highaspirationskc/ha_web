class DashboardController < AuthenticatedController
  def index
    @current_season = Current.season
    @season_date_range = current_season_date_range

    # Calculate team standings using selected season's date range
    @team_standings = Team.all.map do |team|
      latest_activity = EventLog.joins(:event, user: :mentee)
        .where(mentees: { team_id: team.id })
        .where(events: { event_date: @season_date_range })
        .maximum("events.event_date")
      {
        team: team,
        points: team.total_points(@season_date_range),
        hours: team.total_community_service_hours(@season_date_range),
        member_count: team.mentees.count,
        latest_activity: latest_activity || Date.new(1900, 1, 1)
      }
    end.sort_by { |standing| [-standing[:points], -standing[:latest_activity].to_time.to_i] }

    # Get top mentees for the season
    if @current_season && @season_date_range
      mentees = Mentee.includes(:user)

      @top_season_mentees = mentees.map do |mentee|
        latest_event = mentee.user.event_logs.joins(:event)
          .where(events: { event_date: @season_date_range })
          .maximum("events.event_date")
        {
          user: mentee.user,
          points: mentee.total_points(@season_date_range),
          latest_activity: latest_event || Date.new(1900, 1, 1)
        }
      end.select { |m| m[:points] > 0 }
        .sort_by { |m| [-m[:points], -m[:latest_activity].to_time.to_i] }
        .take(5)

      # Get top mentees by community service hours for the season
      @top_service_hours_mentees = mentees.map do |mentee|
        latest_service = mentee.community_service_records
          .where(approved: true)
          .where(event_date: @season_date_range)
          .maximum(:event_date)
        {
          user: mentee.user,
          hours: mentee.total_community_service_hours(@season_date_range),
          latest_activity: latest_service || Date.new(1900, 1, 1)
        }
      end.select { |m| m[:hours] > 0 }
        .sort_by { |m| [-m[:hours], -m[:latest_activity].to_time.to_i] }
        .take(5)
    else
      @top_season_mentees = []
      @top_service_hours_mentees = []
    end
  end
end
