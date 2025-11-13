class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    @users = User.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    # Only allow role assignment by admins (not staff)
    if params[:user][:role].present? && current_user.admin?
      @user.role = params[:user][:role]
    end

    if @user.save
      redirect_to admin_user_path(@user), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = user_params
    # Remove password fields if they're blank (don't update password)
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    # Only allow role changes by admins (not staff) - handle separately from mass assignment
    if params[:user][:role].present? && current_user.admin?
      update_params[:role] = params[:user][:role]
    end

    if @user.update(update_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy!
    redirect_to admin_users_path, notice: "User was successfully destroyed.", status: :see_other
  end

  def activate
    @user.activate!
    redirect_to admin_user_path(@user), notice: "User activated successfully"
  end

  def deactivate
    @user.deactivate!
    redirect_to admin_user_path(@user), notice: "User deactivated successfully"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :active, :team_id, :first_name, :last_name)
  end
end
