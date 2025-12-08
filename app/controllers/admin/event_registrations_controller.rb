class Admin::EventRegistrationsController < Admin::BaseController
  before_action { require_navigation_access(:events) }
  before_action :set_event_registration, only: %i[ show edit update destroy ]

  # GET /admin/event_registrations or /admin/event_registrations.json
  def index
    @event_registrations = EventRegistration.all
  end

  # GET /admin/event_registrations/1 or /admin/event_registrations/1.json
  def show
  end

  # GET /admin/event_registrations/new
  def new
    @event_registration = EventRegistration.new
  end

  # GET /admin/event_registrations/1/edit
  def edit
  end

  # POST /admin/event_registrations or /admin/event_registrations.json
  def create
    @event_registration = EventRegistration.new(event_registration_params)

    respond_to do |format|
      if @event_registration.save
        format.html { redirect_to admin_event_registration_path(@event_registration), notice: "Event registration was successfully created." }
        format.json { render :show, status: :created, location: admin_event_registration_path(@event_registration) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/event_registrations/1 or /admin/event_registrations/1.json
  def update
    respond_to do |format|
      if @event_registration.update(event_registration_params)
        format.html { redirect_to admin_event_registration_path(@event_registration), notice: "Event registration was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_event_registration_path(@event_registration) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/event_registrations/1 or /admin/event_registrations/1.json
  def destroy
    @event_registration.destroy!

    respond_to do |format|
      format.html { redirect_to admin_event_registrations_path, notice: "Event registration was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_registration
      @event_registration = EventRegistration.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_registration_params
      params.expect(event_registration: [ :event_id, :user_id, :registration_date ])
    end
end
