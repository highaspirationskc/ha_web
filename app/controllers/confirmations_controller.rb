class ConfirmationsController < ApplicationController
  layout "sessions"
  before_action :set_user_by_token

  def show
    if @user.nil? || @user.confirmation_token_expired?
      flash[:error] = "Invalid or expired confirmation link"
      redirect_to root_path
    end
    # Otherwise render the password setup form (works for both new users and password reset)
  end

  def confirm
    if @user.nil? || @user.confirmation_token_expired?
      flash[:error] = "Invalid or expired confirmation link"
      redirect_to root_path
      return
    end

    if params[:password].blank?
      flash.now[:error] = "Password is required"
      render :show, status: :unprocessable_entity
      return
    end

    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    if @user.valid?
      was_active = @user.active?
      @user.save!

      if was_active
        # Password reset for existing user
        @user.clear_confirmation_token!
        flash[:success] = "Your password has been updated! You can now log in."
      else
        # New user confirmation
        @user.activate!
        flash[:success] = "Your account has been confirmed! You can now log in."
      end

      redirect_to root_path
    else
      flash.now[:error] = @user.errors.full_messages.join(", ")
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by(confirmation_token: params[:token])
  end
end
