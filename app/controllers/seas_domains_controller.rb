class SeasDomainsController < AuthenticatedController
  before_action { require_navigation_access(:seas_domains) }
  before_action :set_seas_domain, only: %i[ show edit update destroy ]

  def index
    @seas_domains = SeasDomain.order(:position)
    @welcome_image = SeasSetting.welcome_image
  end

  def show
    @seas_questions = @seas_domain.seas_questions.order(:position)
  end

  def new
    @seas_domain = SeasDomain.new
  end

  def edit
  end

  def create
    @seas_domain = SeasDomain.new(seas_domain_params)

    respond_to do |format|
      if @seas_domain.save
        format.html { redirect_to seas_domain_path(@seas_domain), notice: "SEAS domain was successfully created." }
        format.json { render :show, status: :created, location: seas_domain_path(@seas_domain) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @seas_domain.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @seas_domain.update(seas_domain_params)
        format.html { redirect_to seas_domain_path(@seas_domain), notice: "SEAS domain was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: seas_domain_path(@seas_domain) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @seas_domain.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @seas_domain.destroy!

    respond_to do |format|
      format.html { redirect_to seas_domains_path, notice: "SEAS domain was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def update_settings
    if params[:welcome_image_id].present?
      SeasSetting.set("welcome_image_id", params[:welcome_image_id])
    else
      SeasSetting.find_by(key: "welcome_image_id")&.destroy
    end
    redirect_to seas_domains_path, notice: "SEAS settings updated.", status: :see_other
  end

  private

  def set_seas_domain
    @seas_domain = SeasDomain.find(params.expect(:id))
  end

  def seas_domain_params
    params.expect(seas_domain: [ :name, :position ])
  end
end
