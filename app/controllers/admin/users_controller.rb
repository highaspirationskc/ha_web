class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :activate, :deactivate]

  def index
    @users = User.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
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
    params.require(:user).permit(:email, :role, :active)
  end
end
