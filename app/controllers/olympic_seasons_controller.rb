class OlympicSeasonsController < ApplicationController
  before_action :set_olympic_season, only: %i[ show edit update destroy ]

  # GET /olympic_seasons or /olympic_seasons.json
  def index
    @olympic_seasons = OlympicSeason.all
  end

  # GET /olympic_seasons/1 or /olympic_seasons/1.json
  def show
  end

  # GET /olympic_seasons/new
  def new
    @olympic_season = OlympicSeason.new
  end

  # GET /olympic_seasons/1/edit
  def edit
  end

  # POST /olympic_seasons or /olympic_seasons.json
  def create
    @olympic_season = OlympicSeason.new(olympic_season_params)

    respond_to do |format|
      if @olympic_season.save
        format.html { redirect_to @olympic_season, notice: "Olympic season was successfully created." }
        format.json { render :show, status: :created, location: @olympic_season }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @olympic_season.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /olympic_seasons/1 or /olympic_seasons/1.json
  def update
    respond_to do |format|
      if @olympic_season.update(olympic_season_params)
        format.html { redirect_to @olympic_season, notice: "Olympic season was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @olympic_season }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @olympic_season.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /olympic_seasons/1 or /olympic_seasons/1.json
  def destroy
    @olympic_season.destroy!

    respond_to do |format|
      format.html { redirect_to olympic_seasons_path, notice: "Olympic season was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_olympic_season
      @olympic_season = OlympicSeason.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def olympic_season_params
      params.expect(olympic_season: [ :name, :start_month, :start_day, :end_month, :end_day ])
    end
end
