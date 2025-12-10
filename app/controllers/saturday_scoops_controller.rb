class SaturdayScoopsController < AuthenticatedController
  before_action { require_navigation_access(:saturday_scoops) }
  before_action :set_saturday_scoop, only: %i[show edit update destroy publish unpublish]
  before_action :authorize_create, only: %i[new create]
  before_action :authorize_edit, only: %i[edit update]
  before_action :authorize_delete, only: %i[destroy]
  before_action :authorize_publish, only: %i[publish unpublish]

  def index
    @saturday_scoops = SaturdayScoop.recent.includes(:image, :video, :created_by).page(params[:page]).per(20)
  end

  def show
  end

  def new
    @saturday_scoop = SaturdayScoop.new
  end

  def edit
  end

  def create
    @saturday_scoop = SaturdayScoop.new(saturday_scoop_params)
    @saturday_scoop.created_by = current_user

    respond_to do |format|
      if @saturday_scoop.save
        format.html { redirect_to saturday_scoop_path(@saturday_scoop), notice: "Saturday Scoop was successfully created." }
        format.json { render :show, status: :created, location: saturday_scoop_path(@saturday_scoop) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @saturday_scoop.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @saturday_scoop.update(saturday_scoop_params)
        format.html { redirect_to saturday_scoop_path(@saturday_scoop), notice: "Saturday Scoop was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: saturday_scoop_path(@saturday_scoop) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @saturday_scoop.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @saturday_scoop.destroy!

    respond_to do |format|
      format.html { redirect_to saturday_scoops_path, notice: "Saturday Scoop was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def publish
    @saturday_scoop.update!(published: true)
    redirect_to saturday_scoop_path(@saturday_scoop), notice: "Saturday Scoop has been published."
  end

  def unpublish
    @saturday_scoop.update!(published: false)
    redirect_to saturday_scoop_path(@saturday_scoop), notice: "Saturday Scoop has been unpublished."
  end

  private

  def set_saturday_scoop
    @saturday_scoop = SaturdayScoop.find(params.expect(:id))
  end

  def saturday_scoop_params
    params.expect(saturday_scoop: [:title, :author, :description, :image_id, :video_id, :publish_on, :published])
  end

  def authorize_create
    return if current_user.can?(:create, :saturday_scoops)
    redirect_to saturday_scoops_path, alert: "You don't have permission to create Saturday Scoops"
  end

  def authorize_edit
    return if current_user.can?(:edit, :saturday_scoops)
    redirect_to saturday_scoop_path(@saturday_scoop), alert: "You don't have permission to edit Saturday Scoops"
  end

  def authorize_delete
    return if current_user.can?(:delete, :saturday_scoops)
    redirect_to saturday_scoop_path(@saturday_scoop), alert: "You don't have permission to delete Saturday Scoops"
  end

  def authorize_publish
    return if current_user.can?(:publish, :saturday_scoops)
    redirect_to saturday_scoop_path(@saturday_scoop), alert: "You don't have permission to publish Saturday Scoops"
  end
end
