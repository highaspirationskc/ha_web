class SpoofController < AuthenticatedController
  before_action :require_admin

  def create
    user = User.find(params[:user_id])
    session[:spoofed_user_id] = user.id
    redirect_to dashboard_path, notice: "Now viewing as #{user.email}"
  end

  def destroy
    session.delete(:spoofed_user_id)
    redirect_to users_path, notice: "Returned to your account"
  end

  private

  def require_admin
    unless real_current_user&.admin?
      redirect_to dashboard_path, alert: "Only admins can spoof users"
    end
  end
end
