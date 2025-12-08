module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  private

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
