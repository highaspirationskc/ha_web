class Admin::EventsController < Admin::BaseController
  before_action { require_navigation_access(:events) }
  before_action :set_event, only: %i[ show edit update destroy ]
  before_action :authorize_create, only: %i[ new create ]
  before_action :authorize_edit, only: %i[ edit update ]
  before_action :authorize_delete, only: %i[ destroy ]

  # GET /admin/events or /admin/events.json
  def index
    # Get the start date for the calendar (defaults to current month)
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current

    # Get all events (simple_calendar will filter by the displayed month)
    @events = Event.includes(:event_type).order(:event_date)
  end

  # GET /admin/events/1 or /admin/events/1.json
  def show
    # Paginate registered and checked-in users separately
    @registered_logs = @event.event_logs.registered
                             .includes(:user)
                             .order(logged_at: :desc)
                             .page(params[:registered_page]).per(10)

    @arrived_logs = @event.event_logs.arrived
                          .includes(:user)
                          .order(logged_at: :desc)
                          .page(params[:arrived_page]).per(10)
  end

  # GET /admin/events/new
  def new
    @event = Event.new
  end

  # GET /admin/events/1/edit
  def edit
  end

  # POST /admin/events or /admin/events.json
  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to admin_event_path(@event), notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: admin_event_path(@event) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/events/1 or /admin/events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to admin_event_path(@event), notice: "Event was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_event_path(@event) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/events/1 or /admin/events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to admin_events_path, notice: "Event was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.expect(event: [ :name, :description, :event_date, :location, :image_url, :event_type_id, :created_by_id ])
    end

    def authorize_create
      return if current_user.can?(:create, :events)
      redirect_to admin_events_path, alert: "You don't have permission to create events"
    end

    def authorize_edit
      return if current_user.can?(:edit, :events)
      redirect_to admin_event_path(@event), alert: "You don't have permission to edit events"
    end

    def authorize_delete
      return if current_user.can?(:delete, :events)
      redirect_to admin_event_path(@event), alert: "You don't have permission to delete events"
    end
end
