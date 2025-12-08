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
    @available_guardians_for_family = available_guardians_for_family
    @allowed_relationship_types = allowed_relationship_types
    @can_manage_family_members = can_manage_family_members?
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
    @can_edit_profile = can_edit_profile?
    @can_edit_password = can_edit_password?
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
      @can_edit_profile = can_edit_profile?
      @can_edit_password = can_edit_password?
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
    # Only users with mentee profiles can have guardians added
    unless @user.mentee.present?
      redirect_to admin_user_path(@user), alert: "Can only add guardians to mentees"
      return
    end

    guardian_user = User.find_by(id: params[:guardian_user_id])

    unless guardian_user&.guardian.present?
      redirect_to admin_user_path(@user), alert: "Guardian not found"
      return
    end

    family_member = FamilyMember.new(
      guardian_id: guardian_user.guardian.id,
      mentee_id: @user.mentee.id,
      relationship_type: params[:relationship_type]
    )

    if family_member.save
      redirect_to admin_user_path(@user), notice: "Guardian added successfully"
    else
      redirect_to admin_user_path(@user), alert: family_member.errors.full_messages.join(", ")
    end
  end

  def remove_family_member
    return redirect_to admin_user_path(@user), alert: "User is not a mentee" unless @user.mentee.present?

    family_member = @user.mentee.family_members.find_by(id: params[:family_member_id])

    if family_member&.destroy
      redirect_to admin_user_path(@user), notice: "Family member removed successfully"
    else
      redirect_to admin_user_path(@user), alert: "Could not remove family member"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Authorization methods
  def staff_member?
    current_user.staff.present?
  end

  def admin_staff?
    current_user.staff&.admin?
  end

  def authorize_index
    # Superusers see all, mentors see their team, others only see themselves
    true # Everyone can access index, but results are filtered
  end

  def authorize_show
    return if can_manage_user?(@user)

    redirect_to admin_users_path, alert: "You don't have permission to view this user"
  end

  def authorize_edit
    return if can_manage_user?(@user)

    redirect_to admin_users_path, alert: "You don't have permission to edit this user"
  end

  def authorize_create
    return if staff_member?

    redirect_to admin_users_path, alert: "You don't have permission to create users"
  end

  def authorize_destroy
    return if staff_member?

    redirect_to admin_users_path, alert: "You don't have permission to delete users"
  end

  def authorize_activation
    return if staff_member?

    redirect_to admin_users_path, alert: "You don't have permission to activate/deactivate users"
  end

  def authorize_family_member_management
    # Only staff can manage family members
    return if staff_member?

    redirect_to admin_users_path, alert: "You don't have permission to manage family members"
  end

  # Permission check methods
  def can_manage_user?(user)
    return true if user == current_user
    return true if staff_member?
    return true if current_user.mentor.present? && user.mentee&.mentor_id == current_user.mentor.id
    return true if current_user.guardian.present? && current_user.guardian.children.exists?(user.mentee&.id)
    false
  end

  def can_edit_profile?
    staff_member?
  end

  def can_edit_password?
    return true if staff_member?
    return true if @user == current_user
    false
  end

  def can_manage_family_members?
    staff_member?
  end

  # Scoped user list based on current user's permissions
  def users_for_current_user
    return User.all if staff_member?

    if current_user.mentor.present?
      # Mentors can see themselves and their mentees
      mentee_user_ids = current_user.mentor.mentees.joins(:user).pluck("users.id")
      User.where(id: [current_user.id] + mentee_user_ids)
    elsif current_user.guardian.present?
      # Guardians can see themselves and their children
      child_user_ids = current_user.guardian.children.joins(:user).pluck("users.id")
      User.where(id: [current_user.id] + child_user_ids)
    else
      # Everyone else can only see themselves
      User.where(id: current_user.id)
    end
  end

  def user_params_for_create
    return {} unless staff_member?
    params.require(:user).permit(:email, :password, :password_confirmation, :active, :first_name, :last_name)
  end

  def permitted_update_params
    permitted = []

    if staff_member?
      permitted = [:email, :password, :password_confirmation, :active, :first_name, :last_name]
    elsif @user == current_user
      permitted = [:password, :password_confirmation]
    end

    return {} if permitted.empty?
    params.require(:user).permit(permitted)
  end

  def available_guardians_for_family
    return [] unless can_manage_family_members?
    return [] unless @user.mentee.present?

    # Get existing guardian IDs to exclude
    existing_guardian_ids = @user.mentee.guardians.pluck(:id)
    Guardian.where.not(id: existing_guardian_ids).includes(:user)
  end

  def allowed_relationship_types
    return [] unless can_manage_family_members?
    return [] unless @user.mentee.present?

    FamilyMember.relationship_types.keys.map { |k| [k.titleize, k] }
  end
end
