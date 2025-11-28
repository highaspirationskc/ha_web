module Admin
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :require_authentication
      helper_method :current_user, :superuser?
    end

    private

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def require_authentication
      unless current_user
        redirect_to root_path, alert: "You must be logged in to access this page"
      end
    end

    def superuser?
      current_user&.admin? || current_user&.staff?
    end

    def require_superuser
      unless superuser?
        redirect_to admin_dashboard_path, alert: "You don't have permission to access this page"
      end
    end
  end
end
