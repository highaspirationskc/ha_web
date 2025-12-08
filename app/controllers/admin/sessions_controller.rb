class Admin::SessionsController < ApplicationController
  def new
    # Render login form
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      if user.active?
        if user.staff.present?
          session[:user_id] = user.id
          redirect_to admin_dashboard_path, notice: "Logged in successfully"
        else
          flash.now[:alert] = "You don't have permission to access the admin area"
          render :new, status: :unauthorized
        end
      else
        flash.now[:alert] = "Please confirm your email address before logging in"
        render :new, status: :unauthorized
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unauthorized
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out successfully"
  end
end
