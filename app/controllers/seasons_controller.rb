class SeasonsController < AuthenticatedController
  before_action :require_staff

  def update
    season = OlympicSeason.find_by(id: params[:id])
    year = params[:year].to_i

    if season && year > 0
      session[:selected_season_id] = season.id
      session[:selected_season_year] = year
    else
      session.delete(:selected_season_id)
      session.delete(:selected_season_year)
    end

    redirect_back fallback_location: dashboard_path
  end

  def reset
    session.delete(:selected_season_id)
    session.delete(:selected_season_year)

    redirect_back fallback_location: dashboard_path
  end

  private

  def require_staff
    redirect_to dashboard_path, alert: "Access denied" unless current_user&.staff.present?
  end
end
