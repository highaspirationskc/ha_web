module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user, :real_current_user, :spoofing?
  end

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

  def require_authentication
    unless real_current_user
      redirect_to root_path, alert: "You must be logged in to access this page"
    end
  end

  def require_navigation_access(nav_item)
    unless current_user&.can_access?(nav_item)
      redirect_to dashboard_path, alert: "You don't have permission to access this page"
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to dashboard_path, alert: "You don't have permission to access this page"
    end
  end
end
