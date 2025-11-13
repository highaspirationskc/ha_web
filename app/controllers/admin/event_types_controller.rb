class Admin::EventTypesController < Admin::BaseController
  before_action :set_event_type, only: %i[ show edit update destroy ]

  # GET /admin/event_types or /admin/event_types.json
  def index
    @event_types = EventType.all
  end

  # GET /admin/event_types/1 or /admin/event_types/1.json
  def show
  end

  # GET /admin/event_types/new
  def new
    @event_type = EventType.new
  end

  # GET /admin/event_types/1/edit
  def edit
  end

  # POST /admin/event_types or /admin/event_types.json
  def create
    @event_type = EventType.new(event_type_params)

    respond_to do |format|
      if @event_type.save
        format.html { redirect_to admin_event_type_path(@event_type), notice: "Event type was successfully created." }
        format.json { render :show, status: :created, location: admin_event_type_path(@event_type) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/event_types/1 or /admin/event_types/1.json
  def update
    respond_to do |format|
      if @event_type.update(event_type_params)
        format.html { redirect_to admin_event_type_path(@event_type), notice: "Event type was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_event_type_path(@event_type) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/event_types/1 or /admin/event_types/1.json
  def destroy
    @event_type.destroy!

    respond_to do |format|
      format.html { redirect_to admin_event_types_path, notice: "Event type was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_type
      @event_type = EventType.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_type_params
      params.expect(event_type: [ :name, :point_value, :category ])
    end
end
