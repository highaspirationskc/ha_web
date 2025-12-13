class GradeCardsController < AuthenticatedController
  before_action { require_navigation_access(:grade_cards) }

  def index
    @current_season = Current.season
    @season_date_range = current_season_date_range

    @grade_cards = service.list
                     .includes(mentee: :user, medium: [])
                     .order(created_at: :desc)

    if @season_date_range
      @grade_cards = @grade_cards.where(created_at: @season_date_range)
    end

    if params[:mentee_id].present?
      @grade_cards = @grade_cards.where(mentee_id: params[:mentee_id])
      @selected_mentee = Mentee.find_by(id: params[:mentee_id])
    end

    @filterable_mentees = filterable_mentees
    @available_mentees = available_mentees_for_upload
  end

  def show
    @grade_card = service.find(params[:id])
    redirect_to grade_cards_path, alert: "Grade card not found" unless @grade_card
  end

  def create
    mentee = determine_target_mentee

    result = service.create(
      mentee: mentee,
      file: params[:file],
      description: params[:description]
    )

    if result.success?
      redirect_to grade_cards_path, notice: "Grade card added successfully"
    else
      redirect_to grade_cards_path, alert: result.error
    end
  end

  def destroy
    grade_card = service.find(params[:id])
    result = service.delete(grade_card)

    if result.success?
      redirect_to grade_cards_path, notice: "Grade card removed successfully"
    else
      redirect_to grade_cards_path, alert: result.error
    end
  end

  private

  def service
    @service ||= GradeCardsService.new(current_user)
  end

  def available_mentees_for_upload
    if current_user.admin? || current_user.staff?
      Mentee.includes(:user).joins(:user).order("users.first_name, users.last_name")
    elsif current_user.mentor?
      current_user.mentor.mentees.includes(:user).joins(:user).order("users.first_name, users.last_name")
    elsif current_user.guardian?
      current_user.guardian.children.includes(:user).joins(:user).order("users.first_name, users.last_name")
    else
      Mentee.none
    end
  end

  def filterable_mentees
    available_mentees_for_upload.map { |m| ["#{m.user.first_name} #{m.user.last_name}".strip, m.id] }
  end

  def determine_target_mentee
    if current_user.mentee?
      current_user.mentee
    elsif params[:mentee_id].present?
      Mentee.find_by(id: params[:mentee_id])
    end
  end
end
