class TeamsController < AuthenticatedController
  before_action { require_navigation_access(:teams) }
  before_action :set_team, only: %i[ show edit update destroy add_member remove_member ]
  before_action :authorize_create, only: %i[ new create ]
  before_action :authorize_edit, only: %i[ edit update ]
  before_action :authorize_delete, only: %i[ destroy ]
  before_action :authorize_manage_members, only: %i[ add_member remove_member ]

  # GET /admin/teams or /admin/teams.json
  def index
    @teams = Team.all
  end

  # GET /admin/teams/1 or /admin/teams/1.json
  def show
    @current_season = OlympicSeason.current_season

    # Calculate points for each mentee on this team
    @mentee_points = @team.mentees.includes(:user).map do |mentee|
      {
        mentee: mentee,
        user: mentee.user,
        points: mentee.total_points
      }
    end.sort_by { |mp| -mp[:points] }

    # Available mentees that can be added to the team (those not already on a team)
    @available_mentees = Mentee.includes(:user).where(team_id: nil)
  end

  # GET /admin/teams/new
  def new
    @team = Team.new
  end

  # GET /admin/teams/1/edit
  def edit
  end

  # POST /admin/teams or /admin/teams.json
  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save
        format.html { redirect_to team_path(@team), notice: "Team was successfully created." }
        format.json { render :show, status: :created, location: team_path(@team) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/teams/1 or /admin/teams/1.json
  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to team_path(@team), notice: "Team was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: team_path(@team) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/teams/1 or /admin/teams/1.json
  def destroy
    @team.destroy!

    respond_to do |format|
      format.html { redirect_to teams_path, notice: "Team was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /admin/teams/1/add_member
  def add_member
    mentee = Mentee.find_by(id: params[:mentee_id])

    unless mentee
      redirect_to team_path(@team), alert: "Mentee not found"
      return
    end

    mentee.update!(team: @team)
    redirect_to team_path(@team), notice: "#{mentee.user.email} added to team"
  end

  # DELETE /admin/teams/1/remove_member
  def remove_member
    mentee = Mentee.find_by(id: params[:mentee_id])

    unless mentee
      redirect_to team_path(@team), alert: "Mentee not found"
      return
    end

    mentee.update!(team: nil)
    redirect_to team_path(@team), notice: "#{mentee.user.email} removed from team"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def team_params
      params.expect(team: [ :name, :color, :icon_id ])
    end

    def authorize_create
      return if current_user.can?(:create, :teams)
      redirect_to teams_path, alert: "You don't have permission to create teams"
    end

    def authorize_edit
      return if current_user.can?(:edit, :teams)
      redirect_to team_path(@team), alert: "You don't have permission to edit teams"
    end

    def authorize_delete
      return if current_user.can?(:delete, :teams)
      redirect_to team_path(@team), alert: "You don't have permission to delete teams"
    end

    def authorize_manage_members
      return if current_user.can?(:manage_members, :teams)
      redirect_to team_path(@team), alert: "You don't have permission to manage team members"
    end
end
