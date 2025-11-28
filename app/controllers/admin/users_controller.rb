class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :activate, :deactivate, :add_family_member, :remove_family_member]
  before_action :authorize_index, only: [:index]
  before_action :authorize_show, only: [:show]
  before_action :authorize_edit, only: [:edit, :update]
  before_action :authorize_create, only: [:new, :create]
  before_action :authorize_destroy, only: [:destroy]
  before_action :authorize_activation, only: [:activate, :deactivate]
  before_action :authorize_family_member_management, only: [:add_family_member, :remove_family_member]

  def index
    @users = users_for_current_user.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params_for_create)

    if @user.save
      redirect_to admin_user_path(@user), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_users_for_family = available_users_for_family
    @allowed_relationship_types = allowed_relationship_types
    @can_edit_profile = can_edit_profile?
    @can_edit_password = can_edit_password?
    @can_edit_role_and_team = can_edit_role_and_team?
    @can_manage_family_members = can_manage_family_members?
  end

  def update
    permitted = permitted_update_params

    if permitted.empty?
      redirect_to admin_user_path(@user), alert: "You don't have permission to update this user"
      return
    end

    # Remove password fields if they're blank
    if permitted[:password].blank?
      permitted = permitted.except(:password, :password_confirmation)
    end

    if @user.update(permitted)
      redirect_to admin_user_path(@user), notice: "User updated successfully"
    else
      @available_users_for_family = available_users_for_family
      @allowed_relationship_types = allowed_relationship_types
      @can_edit_profile = can_edit_profile?
      @can_edit_password = can_edit_password?
      @can_edit_role_and_team = can_edit_role_and_team?
      @can_manage_family_members = can_manage_family_members?
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

  def add_family_member
    # Only mentees can have parents/guardians added
    unless @user.mentee?
      redirect_to edit_admin_user_path(@user), alert: "Can only add parents/guardians to mentees"
      return
    end

    parent_user = User.find_by(id: params[:related_user_id])

    unless parent_user
      redirect_to edit_admin_user_path(@user), alert: "Parent not found"
      return
    end

    # FamilyMember: user is the parent, related_user is the child (mentee)
    family_member = FamilyMember.new(
      user_id: parent_user.id,
      related_user_id: @user.id,
      relationship_type: params[:relationship_type]
    )

    if family_member.save
      redirect_to edit_admin_user_path(@user), notice: "Parent/guardian added successfully"
    else
      redirect_to edit_admin_user_path(@user), alert: family_member.errors.full_messages.join(", ")
    end
  end

  def remove_family_member
    family_member = @user.reverse_family_members.find_by(id: params[:family_member_id])

    if family_member&.destroy
      redirect_to edit_admin_user_path(@user), notice: "Family member removed successfully"
    else
      redirect_to edit_admin_user_path(@user), alert: "Could not remove family member"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Authorization methods
  def superuser?
    current_user.admin? || current_user.staff?
  end

  def authorize_index
    # Superusers see all, mentors see their team, others only see themselves
    true # Everyone can access index, but results are filtered
  end

  def authorize_show
    return if current_user.can_manage?(@user)

    redirect_to admin_users_path, alert: "You don't have permission to view this user"
  end

  def authorize_edit
    return if current_user.can_manage?(@user)

    redirect_to admin_users_path, alert: "You don't have permission to edit this user"
  end

  def authorize_create
    return if superuser?

    redirect_to admin_users_path, alert: "You don't have permission to create users"
  end

  def authorize_destroy
    return if superuser?

    redirect_to admin_users_path, alert: "You don't have permission to delete users"
  end

  def authorize_activation
    return if superuser?

    redirect_to admin_users_path, alert: "You don't have permission to activate/deactivate users"
  end

  def authorize_family_member_management
    # Only superusers can manage family members
    return if superuser?

    redirect_to admin_users_path, alert: "You don't have permission to manage family members"
  end

  # Permission check methods for views
  def can_edit_profile?
    superuser?
  end

  def can_edit_password?
    return true if superuser?
    return true if @user == current_user
    false
  end

  def can_edit_role_and_team?
    superuser?
  end

  def can_manage_family_members?
    # Only superusers can manage family members
    superuser?
  end

  # Scoped user list based on current user's permissions
  def users_for_current_user
    return User.all if superuser?

    if (current_user.mentor? || current_user.volunteer?) && current_user.team_id
      # Mentors/volunteers can see themselves and all mentees on their team
      User.where(team_id: current_user.team_id, role: :mentee).or(User.where(id: current_user.id))
    elsif current_user.parent?
      # Parents can see themselves and their children
      User.where(id: [current_user.id] + current_user.children.pluck(:id))
    else
      # Everyone else can only see themselves
      User.where(id: current_user.id)
    end
  end

  def user_params_for_create
    return {} unless superuser?
    params.require(:user).permit(:email, :password, :password_confirmation, :active, :team_id, :first_name, :last_name, :role)
  end

  def permitted_update_params
    permitted = []

    if superuser?
      permitted = [:email, :password, :password_confirmation, :active, :team_id, :first_name, :last_name, :role]
    elsif @user == current_user
      permitted = [:password, :password_confirmation]
    end

    return {} if permitted.empty?
    params.require(:user).permit(permitted)
  end

  def available_users_for_family
    return [] unless can_manage_family_members?
    return [] unless @user.mentee?

    # Get existing parent/guardian IDs to exclude
    existing_parent_ids = @user.reverse_family_members.pluck(:user_id)
    User.where(role: :parent).where.not(id: existing_parent_ids)
  end

  def allowed_relationship_types
    return [] unless can_manage_family_members?
    return [] unless @user.mentee?

    [["Parent", "parent"], ["Guardian", "guardian"]]
  end
end
