class UsersController < AuthenticatedController
  before_action { require_navigation_access(:users) }
  before_action :set_user, only: [:show, :edit, :update, :destroy, :activate, :deactivate, :add_family_member, :remove_family_member, :create_guardian, :add_mentee, :remove_mentee]
  before_action :authorize_index, only: [:index]
  before_action :authorize_show, only: [:show]
  before_action :authorize_edit, only: [:edit, :update]
  before_action :authorize_create, only: [:new, :create]
  before_action :authorize_destroy, only: [:destroy]
  before_action :authorize_activation, only: [:activate, :deactivate]
  before_action :authorize_family_member_management, only: [:add_family_member, :remove_family_member, :create_guardian]
  before_action :authorize_mentee_management, only: [:add_mentee, :remove_mentee]

  def index
    @users = users_for_current_user
    @users = apply_role_filter(@users)
    @users = apply_search_filter(@users)
    @users = @users.order(created_at: :desc).page(params[:page])
  end

  def show
    @can_manage_family_members = current_user.can?(:manage_family_members, :users)
    @can_manage_mentees = current_user.can?(:manage_mentees, :users)
    @can_activate_deactivate = current_user.can?(:change_status, :users, @user)
    @can_delete = current_user.can?(:delete, :users, @user)
    @available_guardians_for_family = available_guardians_for_family
    @allowed_relationship_types = allowed_relationship_types
    @available_mentees_for_mentor = available_mentees_for_mentor
  end

  VALID_ROLES = %w[staff mentor mentee guardian volunteer].freeze

  def new
    @user = User.new(active: true)
    load_role_form_data
  end

  def create
    @role = params[:role]

    unless VALID_ROLES.include?(@role)
      @user = User.new(user_params_for_create)
      @user.errors.add(:base, "Role is required")
      load_role_form_data
      render :new, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @user = User.new(user_params_for_create)
      if @user.password.blank?
        @user.password = generate_temporary_password
        @user.password_confirmation = @user.password
      end
      @user.save!
      create_role_profile!
      redirect_to user_path(@user), notice: "User was successfully created."
    end
  rescue ActiveRecord::RecordInvalid
    load_role_form_data
    render :new, status: :unprocessable_entity
  end

  def edit
    @can_edit_profile = current_user.can?(:edit, :users)
    @can_edit_password = current_user.can?(:edit, :users) || @user == current_user
    @can_delete = current_user.can?(:delete, :users, @user)
    @can_change_status = current_user.can?(:change_status, :users, @user)
    load_mentee_form_data if @user.mentee.present? && @can_edit_profile
  end

  def update
    permitted = permitted_update_params

    if permitted.empty?
      redirect_to user_path(@user), alert: "You don't have permission to update this user"
      return
    end

    # Remove password fields if they're blank
    if permitted[:password].blank?
      permitted = permitted.except(:password, :password_confirmation)
    end

    ActiveRecord::Base.transaction do
      @user.update!(permitted)
      update_mentee_if_present
    end

    redirect_to user_path(@user), notice: "User updated successfully"
  rescue ActiveRecord::RecordInvalid
    @can_edit_profile = current_user.can?(:edit, :users)
    @can_edit_password = current_user.can?(:edit, :users) || @user == current_user
    @can_delete = current_user.can?(:delete, :users, @user)
    @can_change_status = current_user.can?(:change_status, :users, @user)
    load_mentee_form_data if @user.mentee.present? && @can_edit_profile
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @user.destroy!
    redirect_to users_path, notice: "User was successfully destroyed.", status: :see_other
  end

  def activate
    @user.activate!
    redirect_to user_path(@user), notice: "User activated successfully"
  end

  def deactivate
    @user.deactivate!
    redirect_to user_path(@user), notice: "User deactivated successfully"
  end

  def add_family_member
    # Only users with mentee profiles can have guardians added
    unless @user.mentee.present?
      redirect_to user_path(@user), alert: "Can only add guardians to mentees"
      return
    end

    guardian_user = User.find_by(id: params[:guardian_user_id])

    unless guardian_user&.guardian.present?
      redirect_to user_path(@user), alert: "Guardian not found"
      return
    end

    family_member = FamilyMember.new(
      guardian_id: guardian_user.guardian.id,
      mentee_id: @user.mentee.id,
      relationship_type: params[:relationship_type]
    )

    if family_member.save
      redirect_to user_path(@user), notice: "Guardian added successfully"
    else
      redirect_to user_path(@user), alert: family_member.errors.full_messages.join(", ")
    end
  end

  def remove_family_member
    return redirect_to user_path(@user), alert: "User is not a mentee" unless @user.mentee.present?

    family_member = @user.mentee.family_members.find_by(id: params[:family_member_id])

    if family_member&.destroy
      redirect_to user_path(@user), notice: "Family member removed successfully"
    else
      redirect_to user_path(@user), alert: "Could not remove family member"
    end
  end

  def create_guardian
    return redirect_to user_path(@user), alert: "User is not a mentee" unless @user.mentee.present?

    ActiveRecord::Base.transaction do
      # Create guardian user with random temporary password
      guardian_user = User.new(
        email: params[:email],
        first_name: params[:first_name],
        last_name: params[:last_name],
        password: generate_temporary_password,
        active: false
      )
      guardian_user.save!

      # Create guardian profile
      guardian = Guardian.create!(user: guardian_user)

      # Create family member relationship
      FamilyMember.create!(
        guardian: guardian,
        mentee: @user.mentee,
        relationship_type: params[:relationship_type]
      )

      # Send confirmation email
      guardian_user.send_confirmation_email

      redirect_to user_path(@user), notice: "Guardian created successfully. A confirmation email has been sent to #{guardian_user.email}."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to user_path(@user), alert: "Could not create guardian: #{e.record.errors.full_messages.join(', ')}"
  end

  def add_mentee
    return redirect_to user_path(@user), alert: "User is not a mentor" unless @user.mentor.present?

    mentee = Mentee.find_by(id: params[:mentee_id])

    unless mentee
      redirect_to user_path(@user), alert: "Mentee not found"
      return
    end

    if mentee.update(mentor: @user.mentor)
      redirect_to user_path(@user), notice: "Mentee added successfully"
    else
      redirect_to user_path(@user), alert: mentee.errors.full_messages.join(", ")
    end
  end

  def remove_mentee
    return redirect_to user_path(@user), alert: "User is not a mentor" unless @user.mentor.present?

    mentee = @user.mentor.mentees.find_by(id: params[:mentee_id])

    if mentee&.update(mentor: nil)
      redirect_to user_path(@user), notice: "Mentee removed successfully"
    else
      redirect_to user_path(@user), alert: "Could not remove mentee"
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

  def authorize_index
    # Superusers see all, mentors see their team, others only see themselves
    true # Everyone can access index, but results are filtered
  end

  def authorize_show
    return if can_manage_user?(@user)

    redirect_to users_path, alert: "You don't have permission to view this user"
  end

  def authorize_edit
    return if can_manage_user?(@user)

    redirect_to users_path, alert: "You don't have permission to edit this user"
  end

  def authorize_create
    return if current_user.can?(:create, :users)

    redirect_to users_path, alert: "You don't have permission to create users"
  end

  def authorize_destroy
    return if current_user.can?(:delete, :users, @user)

    if @user == current_user
      redirect_to user_path(@user), alert: "You cannot delete yourself"
    else
      redirect_to users_path, alert: "You don't have permission to delete users"
    end
  end

  def authorize_activation
    return if current_user.can?(:change_status, :users, @user)

    if @user == current_user
      redirect_to user_path(@user), alert: "You cannot activate/deactivate yourself"
    else
      redirect_to users_path, alert: "You don't have permission to activate/deactivate users"
    end
  end

  def authorize_family_member_management
    return if current_user.can?(:manage_family_members, :users)

    redirect_to users_path, alert: "You don't have permission to manage family members"
  end

  def authorize_mentee_management
    return if current_user.can?(:manage_mentees, :users)

    redirect_to users_path, alert: "You don't have permission to manage mentees"
  end

  # Permission check methods
  def can_manage_user?(user)
    return true if user == current_user
    return true if staff_member?
    return true if current_user.mentor.present? && user.mentee&.mentor_id == current_user.mentor.id
    return true if current_user.guardian.present? && current_user.guardian.children.exists?(user.mentee&.id)
    false
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

    if current_user.can?(:edit, :users)
      permitted = [:email, :password, :password_confirmation, :first_name, :last_name]
      permitted << :active if current_user.can?(:change_status, :users, @user)
    elsif @user == current_user
      permitted = [:password, :password_confirmation]
    end

    return {} if permitted.empty?
    params.require(:user).permit(permitted)
  end

  def available_guardians_for_family
    return [] unless current_user.can?(:manage_family_members, :users)
    return [] unless @user.mentee.present?

    # Get existing guardian IDs to exclude
    existing_guardian_ids = @user.mentee.guardians.pluck(:id)
    Guardian.where.not(id: existing_guardian_ids).includes(:user)
  end

  def allowed_relationship_types
    return [] unless current_user.can?(:manage_family_members, :users)
    return [] unless @user.mentee.present?

    FamilyMember.relationship_types.keys.map { |k| [k.titleize, k] }
  end

  def available_mentees_for_mentor
    return [] unless current_user.can?(:manage_mentees, :users)
    return [] unless @user.mentor.present?

    # Get mentees not already assigned to this mentor (unassigned)
    Mentee.where(mentor_id: nil).includes(:user)
  end

  def apply_role_filter(users)
    return users if params[:role].blank?

    case params[:role]
    when "staff"
      users.joins(:staff)
    when "mentor"
      users.joins(:mentor)
    when "mentee"
      users.joins(:mentee)
    when "guardian"
      users.joins(:guardian)
    when "volunteer"
      users.joins(:volunteer)
    else
      users
    end
  end

  def apply_search_filter(users)
    return users if params[:search].blank?

    # Split search into words and match each word against any field
    words = params[:search].downcase.split(/\s+/).reject(&:blank?)
    return users if words.empty?

    words.each do |word|
      term = "%#{word}%"
      users = users.where(
        "LOWER(email) LIKE :term OR LOWER(first_name) LIKE :term OR LOWER(last_name) LIKE :term",
        term: term
      )
    end

    users
  end

  def load_mentee_form_data
    @teams = Team.all.order(:name)
    @mentors = Mentor.includes(:user).all
  end

  def load_role_form_data
    @teams = Team.all.order(:name)
    @mentors = Mentor.includes(:user).all
  end

  def create_role_profile!
    case @role
    when "staff"
      Staff.create!(user: @user, permission_level: staff_params[:permission_level] || :standard)
    when "mentor"
      Mentor.create!(user: @user)
    when "mentee"
      mentee_attrs = { user: @user }
      if params[:mentee].present?
        mentee_attrs[:team_id] = params[:mentee][:team_id].presence
        mentee_attrs[:mentor_id] = params[:mentee][:mentor_id].presence
      end
      Mentee.create!(mentee_attrs)
    when "guardian"
      Guardian.create!(user: @user)
    when "volunteer"
      Volunteer.create!(user: @user)
    end
  end

  def staff_params
    params[:staff].present? ? params.require(:staff).permit(:permission_level) : {}
  end

  def update_mentee_if_present
    return unless @user.mentee.present? && current_user.can?(:edit, :users) && params[:mentee].present?

    mentee_params = params.require(:mentee).permit(:team_id, :mentor_id)
    # Convert empty strings to nil for optional associations
    mentee_params[:team_id] = nil if mentee_params[:team_id].blank?
    mentee_params[:mentor_id] = nil if mentee_params[:mentor_id].blank?
    @user.mentee.update!(mentee_params)
  end

  def generate_temporary_password
    # Generate a password that meets complexity requirements
    # At least 8 chars, uppercase, number, special character
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + %w[! @ # $ % ^ & *]
    password = ""
    password += ("A".."Z").to_a.sample # uppercase
    password += ("0".."9").to_a.sample # number
    password += %w[! @ # $ % ^ & *].sample # special
    password += Array.new(13) { chars.sample }.join # fill to 16 chars
    password.chars.shuffle.join
  end
end
