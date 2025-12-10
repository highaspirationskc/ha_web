class CommunityServiceRecordsController < AuthenticatedController
  before_action { require_navigation_access(:community_service) }
  before_action :set_record, only: [:show, :edit, :update, :destroy]
  before_action :authorize_create, only: [:new, :create]
  before_action :authorize_edit, only: [:edit, :update]
  before_action :authorize_delete, only: [:destroy]

  def index
    @current_season = Current.season
    @season_date_range = current_season_date_range

    @records = accessible_records
                 .includes(mentee: :user)
                 .order(event_date: :desc)

    # Filter by season if available
    if @season_date_range
      @records = @records.where(event_date: @season_date_range)
    end

    # Filter by mentee if specified
    if params[:mentee_id].present?
      @records = @records.where(mentee_id: params[:mentee_id])
      @selected_mentee = Mentee.find_by(id: params[:mentee_id])
    end

    # Build list of mentees for the filter dropdown
    @filterable_mentees = filterable_mentees
  end

  def show
  end

  def new
    if current_user.mentee?
      @record = current_user.mentee.community_service_records.build
    else
      @record = CommunityServiceRecord.new
      @mentees = available_mentees
    end
  end

  def create
    if current_user.mentee? && !params[:community_service_record][:mentee_id].present?
      @record = current_user.mentee.community_service_records.build(record_params)
    else
      @record = CommunityServiceRecord.new(record_params_with_mentee)
      # Verify the mentee is accessible to this user
      unless available_mentees.exists?(id: @record.mentee_id)
        redirect_to community_service_records_path, alert: "Invalid mentee selected"
        return
      end
    end

    if @record.save
      redirect_path = params[:redirect_to].presence || community_service_records_path
      redirect_to redirect_path, notice: "Community service record was successfully created."
    else
      @mentees = available_mentees unless current_user.mentee?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @mentees = available_mentees unless current_user.mentee?
  end

  def update
    if @record.update(update_params)
      # Send denial message if record was denied and a reason was provided
      if @record.approved == false && params[:denial_reason].present?
        send_denial_message(@record, params[:denial_reason])
      end

      redirect_path = params[:redirect_to].presence || community_service_records_path
      redirect_to redirect_path, notice: "Community service record was successfully updated."
    else
      @mentees = available_mentees unless current_user.mentee?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record.destroy!
    redirect_to community_service_records_path, notice: "Community service record was successfully deleted."
  end

  private

  def set_record
    @record = accessible_records.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to community_service_records_path, alert: "Record not found"
  end

  def accessible_records
    if current_user.admin? || current_user.staff?
      CommunityServiceRecord.all
    elsif current_user.mentor?
      mentee_ids = current_user.mentor.mentees.pluck(:id)
      CommunityServiceRecord.where(mentee_id: mentee_ids)
    elsif current_user.mentee?
      current_user.mentee.community_service_records
    else
      CommunityServiceRecord.none
    end
  end

  def available_mentees
    if current_user.admin? || current_user.staff?
      Mentee.includes(:user).all
    elsif current_user.mentor?
      current_user.mentor.mentees.includes(:user)
    else
      Mentee.none
    end
  end

  def filterable_mentees
    mentees = if current_user.admin? || current_user.staff?
      Mentee.includes(:user).joins(:user).order("users.first_name, users.last_name")
    elsif current_user.mentor?
      current_user.mentor.mentees.includes(:user).joins(:user).order("users.first_name, users.last_name")
    else
      Mentee.none
    end

    mentees.map { |m| ["#{m.user.first_name} #{m.user.last_name}".strip, m.id] }
  end

  def record_params
    params.require(:community_service_record).permit(:event, :description, :event_date, :hours)
  end

  def record_params_with_mentee
    params.require(:community_service_record).permit(:mentee_id, :event, :description, :event_date, :hours)
  end

  def update_params
    if current_user.admin? || current_user.staff?
      params.require(:community_service_record).permit(:event, :description, :event_date, :hours, :approved)
    elsif current_user.mentor?
      # Mentors can edit all fields for their mentees' records
      params.require(:community_service_record).permit(:event, :description, :event_date, :hours, :approved)
    else
      # Mentees can edit their own records (but not approved status)
      params.require(:community_service_record).permit(:event, :description, :event_date, :hours)
    end
  end

  def send_denial_message(record, reason)
    mentee_user = record.mentee.user
    subject = "Community Service Record Denied: #{record.event}"
    body = <<~BODY
      Your community service record has been denied.

      **Activity:** #{record.event}
      **Date:** #{record.event_date.strftime("%B %d, %Y")}
      **Hours:** #{record.hours}

      **Reason for denial:**
      #{reason}

      If you have questions, please reply to this message.
    BODY

    msg = Message.create!(
      author: current_user,
      subject: subject,
      message: body
    )

    MessageRecipient.create!(
      message: msg,
      recipient: mentee_user
    )
  end

  def authorize_create
    return if current_user.can?(:create, :community_service_records)
    redirect_to community_service_records_path, alert: "You don't have permission to create community service records"
  end

  def authorize_edit
    return if current_user.can?(:edit, :community_service_records)
    redirect_to community_service_records_path, alert: "You don't have permission to edit community service records"
  end

  def authorize_delete
    return if current_user.can?(:delete, :community_service_records)
    redirect_to community_service_records_path, alert: "You don't have permission to delete community service records"
  end
end
