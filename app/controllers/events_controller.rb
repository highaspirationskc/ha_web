class EventsController < AuthenticatedController
  skip_before_action :require_authentication, only: [:kiosk]
  before_action(except: [:kiosk]) { require_navigation_access(:events) }
  before_action :set_event, only: %i[ show edit update destroy kiosk kiosk_search kiosk_checkin kiosk_exit ]
  before_action :authorize_create, only: %i[ new create ]
  before_action :authorize_edit, only: %i[ edit update ]
  before_action :authorize_delete, only: %i[ destroy ]
  before_action :authorize_kiosk_action, only: %i[ kiosk_search kiosk_checkin kiosk_exit ]

  # GET /admin/events or /admin/events.json
  def index
    load_calendar_data
    @view_mode = params[:view] == "list" ? :list : :calendar
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
        format.html { redirect_to event_path(@event), notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: event_path(@event) }
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
        format.html { redirect_to event_path(@event), notice: "Event was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: event_path(@event) }
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
      format.html { redirect_to events_path, notice: "Event was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # GET /events/:id/kiosk - Public kiosk view
  def kiosk
    render layout: "kiosk"
  end

  # GET /events/:id/kiosk_search - Search all users (requires auth)
  def kiosk_search
    query = params[:query].to_s.strip

    users = User.where("LOWER(first_name || ' ' || last_name) LIKE ?", "%#{query.downcase}%")
      .or(User.where("LOWER(email) LIKE ?", "%#{query.downcase}%"))
      .limit(20)
      .map { |user| { id: user.id, name: "#{user.first_name} #{user.last_name}", email: user.email } }

    render json: { users: users }
  end

  # POST /events/:id/kiosk_checkin - Check in a user (requires auth)
  def kiosk_checkin
    user = User.find(params[:user_id])

    event_log = EventLog.new(event: @event, user: user, log_type: :arrived)

    if event_log.save
      render json: { success: true, name: "#{user.first_name} #{user.last_name}" }
    else
      render json: { success: false, errors: event_log.errors.full_messages }
    end
  end

  # GET /events/:id/kiosk_exit - Exit kiosk mode (requires auth)
  def kiosk_exit
    respond_to do |format|
      format.html { redirect_to event_path(@event) }
      format.json { render json: { success: true, redirect_url: event_path(@event) } }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.expect(event: [ :name, :description, :event_date, :location, :image_id, :event_type_id, :created_by_id ])
    end

    def authorize_create
      return if current_user.can?(:create, :events)
      redirect_to events_path, alert: "You don't have permission to create events"
    end

    def authorize_edit
      return if current_user.can?(:edit, :events)
      redirect_to event_path(@event), alert: "You don't have permission to edit events"
    end

    def authorize_delete
      return if current_user.can?(:delete, :events)
      redirect_to event_path(@event), alert: "You don't have permission to delete events"
    end

    def authorize_kiosk_action
      return if current_user&.can?(:edit, :events)
      respond_to do |format|
        format.html { redirect_to login_path, alert: "You must be logged in as staff to perform this action" }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
    end

    def load_calendar_data
      @current_season = Current.season
      @season_date_range = current_season_date_range

      # Get the start date for the calendar
      # If viewing a different season and no explicit start_date, default to season start
      if params[:start_date].present?
        @start_date = Date.parse(params[:start_date])
      elsif viewing_different_season? && @season_date_range
        @start_date = @season_date_range.begin
      else
        @start_date = Date.current
      end

      # Filter events to the selected season's date range
      if @season_date_range
        @events = Event.includes(:event_type)
                       .where(event_date: @season_date_range)
                       .order(:event_date)
      else
        @events = Event.includes(:event_type).order(:event_date)
      end
    end
end
