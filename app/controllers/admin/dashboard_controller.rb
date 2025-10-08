class Admin::DashboardController < Admin::BaseController
  def index
    @total_users = User.count
    @active_users = User.where(active: true).count
    @inactive_users = User.where(active: false).count
    @users_by_role = User.group(:role).count
  end
end
