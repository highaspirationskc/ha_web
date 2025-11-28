class Admin::TeamsController < Admin::BaseController
  before_action :require_superuser
  before_action :set_team, only: %i[ show edit update destroy ]

  # GET /admin/teams or /admin/teams.json
  def index
    @teams = Team.all
  end

  # GET /admin/teams/1 or /admin/teams/1.json
  def show
    @current_season = OlympicSeason.current_season

    # Calculate points for each user on this team
    @user_points = @team.users.map do |user|
      {
        user: user,
        points: user.total_points
      }
    end.sort_by { |up| -up[:points] }
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
        format.html { redirect_to admin_team_path(@team), notice: "Team was successfully created." }
        format.json { render :show, status: :created, location: admin_team_path(@team) }
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
        format.html { redirect_to admin_team_path(@team), notice: "Team was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_team_path(@team) }
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
      format.html { redirect_to admin_teams_path, notice: "Team was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def team_params
      params.expect(team: [ :name, :color, :icon_url ])
    end
end
