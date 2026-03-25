class IncentivesController < AuthenticatedController
  before_action { require_navigation_access(:incentives) }
  before_action :set_incentive, only: %i[edit update destroy]
  before_action :authorize_create, only: %i[new create]
  before_action :authorize_edit, only: %i[edit update]
  before_action :authorize_delete, only: %i[destroy]

  # GET /incentives
  def index
    @incentives = Incentive.includes(:image)

    # Filter by type
    case params[:filter]
    when "team"
      @incentives = @incentives.team
    when "individual"
      @incentives = @incentives.individual
    end

    # Order: active first, then by name
    @incentives = @incentives.order(active: :desc, name: :asc).page(params[:page]).per(10)
    @current_filter = params[:filter] || "all"
  end

  # GET /incentives/new
  def new
    @incentive = Incentive.new(active: true)
  end

  # GET /incentives/1/edit
  def edit
  end

  # POST /incentives
  def create
    @incentive = Incentive.new(incentive_params)
    @incentive.created_by = current_user

    respond_to do |format|
      if @incentive.save
        format.html { redirect_to incentives_path, notice: "Incentive was successfully created." }
        format.json { render json: @incentive, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @incentive.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /incentives/1
  def update
    respond_to do |format|
      if @incentive.update(incentive_params)
        format.html { redirect_to incentives_path, notice: "Incentive was successfully updated.", status: :see_other }
        format.json { render json: @incentive, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @incentive.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /incentives/1
  def destroy
    @incentive.destroy!

    respond_to do |format|
      format.html { redirect_to incentives_path, notice: "Incentive was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_incentive
    @incentive = Incentive.find(params.expect(:id))
  end

  def incentive_params
    params.expect(incentive: [:name, :description, :point_cost, :incentive_type, :active, :image_id])
  end

  def authorize_create
    return if current_user.can?(:create, :incentives)
    redirect_to incentives_path, alert: "You don't have permission to create incentives"
  end

  def authorize_edit
    return if current_user.can?(:edit, :incentives)
    redirect_to incentives_path, alert: "You don't have permission to edit incentives"
  end

  def authorize_delete
    return if current_user.can?(:delete, :incentives)
    redirect_to incentives_path, alert: "You don't have permission to delete incentives"
  end
end
