# frozen_string_literal: true

# Provides authentication that supports both session (web) and token (API) auth.
# Use this for endpoints that need to be accessible from both web and mobile apps.
module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_api_authentication
  end

  private

  def require_api_authentication
    unless api_current_user
      respond_to do |format|
        format.html { redirect_to root_path, alert: "You must be logged in to access this page" }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
    end
  end

  def api_current_user
    @api_current_user ||= session_user || token_user
  end

  def session_user
    return nil unless session[:user_id]

    if session[:spoofed_user_id].present?
      real_user = User.find_by(id: session[:user_id])
      return User.find_by(id: session[:spoofed_user_id]) if real_user&.admin?
    end

    User.find_by(id: session[:user_id])
  end

  def token_user
    token = request.headers["Authorization"]&.sub(/^Bearer /, "")
    AuthService.authenticate_token(token)
  end
end
