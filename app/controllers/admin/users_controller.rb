class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :activate, :deactivate, :add_relationship, :remove_relationship]
  before_action :authorize_index, only: [:index]
  before_action :authorize_show, only: [:show]
  before_action :authorize_edit, only: [:edit, :update]
  before_action :authorize_create, only: [:new, :create]
  before_action :authorize_destroy, only: [:destroy]
  before_action :authorize_activation, only: [:activate, :deactivate]
  before_action :authorize_relationship_management, only: [:add_relationship, :remove_relationship]

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
    @available_users_for_relationship = available_users_for_relationship
    @allowed_relationship_types = allowed_relationship_types
    @can_edit_profile = can_edit_profile?
    @can_edit_password = can_edit_password?
    @can_edit_role_and_team = can_edit_role_and_team?
    @can_manage_relationships = can_manage_relationships?
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
      @available_users_for_relationship = available_users_for_relationship
      @allowed_relationship_types = allowed_relationship_types
      @can_edit_profile = can_edit_profile?
      @can_edit_password = can_edit_password?
      @can_edit_role_and_team = can_edit_role_and_team?
      @can_manage_relationships = can_manage_relationships?
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

  def add_relationship
    related_user = User.find_by(id: params[:related_user_id])

    unless related_user
      redirect_to edit_admin_user_path(@user), alert: "User not found"
      return
    end

    # If mentor is adding a mentee, assign mentee to mentor's team
    if current_user.mentor? && @user == current_user && related_user.mentee?
      related_user.update(team_id: current_user.team_id)
    end

    relationship = @user.user_relationships.build(
      related_user_id: related_user.id,
      relationship_type: params[:relationship_type]
    )

    if relationship.save
      redirect_to edit_admin_user_path(@user), notice: "Relationship added successfully"
    else
      redirect_to edit_admin_user_path(@user), alert: relationship.errors.full_messages.join(", ")
    end
  end

  def remove_relationship
    relationship = @user.user_relationships.find_by(id: params[:relationship_id]) ||
                   @user.reverse_relationships.find_by(id: params[:relationship_id])

    if relationship&.destroy
      redirect_to edit_admin_user_path(@user), notice: "Relationship removed successfully"
    else
      redirect_to edit_admin_user_path(@user), alert: "Could not remove relationship"
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
    return if superuser?
    return if @user == current_user
    return if current_user.mentor? && current_user.team_id && @user.team_id == current_user.team_id
    return if current_user.parent? && current_user.children.include?(@user)

    redirect_to admin_users_path, alert: "You don't have permission to view this user"
  end

  def authorize_edit
    return if superuser?
    return if @user == current_user # Can always edit self (for password)
    return if current_user.mentor? && current_user.team_id && @user.team_id == current_user.team_id
    return if current_user.parent? && current_user.children.include?(@user)

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

  def authorize_relationship_management
    return if superuser?
    # Mentors can manage relationships for themselves (adding mentees to their team)
    return if current_user.mentor? && @user == current_user && current_user.team_id

    redirect_to admin_users_path, alert: "You don't have permission to manage relationships"
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

  def can_manage_relationships?
    return true if superuser?
    # Mentors can add mentees to their team
    return true if current_user.mentor? && @user == current_user && current_user.team_id
    false
  end

  # Scoped user list based on current user's permissions
  def users_for_current_user
    return User.all if superuser?

    if current_user.mentor? && current_user.team_id
      User.where(team_id: current_user.team_id).or(User.where(id: current_user.id))
    elsif current_user.parent?
      User.where(id: [current_user.id] + current_user.children.pluck(:id))
    else
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

  def available_users_for_relationship
    return [] unless can_manage_relationships?

    if superuser?
      # Admin/staff editing a mentor: show all mentees to add to mentor's team
      if @user.mentor? && @user.team_id
        User.where(role: :mentee).where.not(id: @user.id)
      # Admin/staff editing a parent: show all mentees to add as children
      elsif @user.parent?
        User.where(role: :mentee).where.not(id: @user.id)
      # Admin/staff editing a mentee: show all parents to link
      elsif @user.mentee?
        User.where(role: :parent).where.not(id: @user.id)
      else
        []
      end
    elsif current_user.mentor? && @user == current_user
      # Mentor adding mentees to their team
      User.where(role: :mentee).where.not(id: @user.id)
    else
      []
    end
  end

  def allowed_relationship_types
    return [] unless can_manage_relationships?

    case @user.role
    when "mentor"
      [["Mentee", "mentor"]]
    when "mentee"
      [["Parent", "parent"]]
    when "parent"
      [["Child", "parent"]]
    else
      []
    end
  end
end
