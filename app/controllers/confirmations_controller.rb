class ConfirmationsController < ApplicationController
  skip_before_action :require_authentication

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user.nil?
      flash[:error] = "Invalid confirmation token"
      redirect_to root_path
    elsif @user.active?
      flash[:notice] = "Your account is already confirmed. Please log in."
      redirect_to root_path
    else
      @user.activate!
      flash[:success] = "Your account has been confirmed! You can now log in."
      redirect_to root_path
    end
  end
end
