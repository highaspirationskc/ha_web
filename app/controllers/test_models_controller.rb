class TestModelsController < ApplicationController
  before_action :set_test_model, only: %i[ show edit update destroy ]

  # GET /test_models or /test_models.json
  def index
    @test_models = TestModel.all
  end

  # GET /test_models/1 or /test_models/1.json
  def show
  end

  # GET /test_models/new
  def new
    @test_model = TestModel.new
  end

  # GET /test_models/1/edit
  def edit
  end

  # POST /test_models or /test_models.json
  def create
    @test_model = TestModel.new(test_model_params)

    respond_to do |format|
      if @test_model.save
        format.html { redirect_to @test_model, notice: "Test model was successfully created." }
        format.json { render :show, status: :created, location: @test_model }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @test_model.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /test_models/1 or /test_models/1.json
  def update
    respond_to do |format|
      if @test_model.update(test_model_params)
        format.html { redirect_to @test_model, notice: "Test model was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @test_model }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @test_model.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /test_models/1 or /test_models/1.json
  def destroy
    @test_model.destroy!

    respond_to do |format|
      format.html { redirect_to test_models_path, notice: "Test model was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_test_model
      @test_model = TestModel.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def test_model_params
      params.expect(test_model: [ :name ])
    end
end
