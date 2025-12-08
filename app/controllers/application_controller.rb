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

  helper_method :current_user, :real_current_user, :spoofing?
end
