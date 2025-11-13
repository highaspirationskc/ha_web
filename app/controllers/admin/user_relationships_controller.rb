class Admin::UserRelationshipsController < Admin::BaseController
  before_action :set_user_relationship, only: %i[ show edit update destroy ]

  # GET /admin/user_relationships or /admin/user_relationships.json
  def index
    @user_relationships = UserRelationship.all
  end

  # GET /admin/user_relationships/1 or /admin/user_relationships/1.json
  def show
  end

  # GET /admin/user_relationships/new
  def new
    @user_relationship = UserRelationship.new
  end

  # GET /admin/user_relationships/1/edit
  def edit
  end

  # POST /admin/user_relationships or /admin/user_relationships.json
  def create
    @user_relationship = UserRelationship.new(user_relationship_params)

    respond_to do |format|
      if @user_relationship.save
        format.html { redirect_to admin_user_relationship_path(@user_relationship), notice: "User relationship was successfully created." }
        format.json { render :show, status: :created, location: admin_user_relationship_path(@user_relationship) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user_relationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/user_relationships/1 or /admin/user_relationships/1.json
  def update
    respond_to do |format|
      if @user_relationship.update(user_relationship_params)
        format.html { redirect_to admin_user_relationship_path(@user_relationship), notice: "User relationship was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: admin_user_relationship_path(@user_relationship) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user_relationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/user_relationships/1 or /admin/user_relationships/1.json
  def destroy
    @user_relationship.destroy!

    respond_to do |format|
      format.html { redirect_to admin_user_relationships_path, notice: "User relationship was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_relationship
      @user_relationship = UserRelationship.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_relationship_params
      params.expect(user_relationship: [ :user_id, :related_user_id, :relationship_type ])
    end
end
