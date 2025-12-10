class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    if spoofing?
      @current_user ||= User.find_by(id: session[:spoofed_user_id])
    else
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  def real_current_user
    @real_current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def spoofing?
    session[:spoofed_user_id].present? && real_current_user&.admin?
  end

  def unread_message_count
    return 0 unless current_user
    @unread_message_count ||= begin
      # Count unread threads (root messages with any unread message for this user)
      unread_message_ids = current_user.message_recipients.unread.pluck(:message_id)
      return 0 if unread_message_ids.empty?

      # Get root IDs for these unread messages
      unread_messages = Message.where(id: unread_message_ids)
      root_ids = unread_messages.map { |m| m.parent_id || m.id }.uniq
      root_ids.count
    end
  end

  def current_season
    @current_season ||= begin
      if current_user&.staff.present? && session[:selected_season_id].present?
        OlympicSeason.find_by(id: session[:selected_season_id]) || OlympicSeason.current_season
      else
        OlympicSeason.current_season
      end
    end
  end

  def current_season_year
    @current_season_year ||= begin
      if current_user&.staff.present? && session[:selected_season_year].present?
        session[:selected_season_year].to_i
      else
        Date.current.year
      end
    end
  end

  def current_season_date_range
    return nil unless current_season
    OlympicSeasonService.new(current_season).date_range(current_season_year)
  end

  def set_current_season
    Current.season = current_season
  end

  def can_switch_season?
    current_user&.staff.present?
  end

  def viewing_historical_season?
    return false unless current_season && OlympicSeason.current_season

    actual_service = OlympicSeasonService.new(OlympicSeason.current_season)
    actual_range = actual_service.date_range_from_reference_date

    current_range = current_season_date_range
    current_range != actual_range
  end

  helper_method :current_user, :real_current_user, :spoofing?, :unread_message_count, :current_season, :current_season_year, :current_season_date_range, :can_switch_season?, :viewing_historical_season?
end
