class FamilyMembersController < ApplicationController
  before_action { require_navigation_access(:users) }
  before_action :set_family_member, only: %i[ show edit update destroy ]

  # GET /admin/family_members or /admin/family_members.json
  def index
    @family_members = FamilyMember.all
  end

  # GET /admin/family_members/1 or /admin/family_members/1.json
  def show
  end

  # GET /admin/family_members/new
  def new
    @family_member = FamilyMember.new
  end

  # GET /admin/family_members/1/edit
  def edit
  end

  # POST /admin/family_members or /admin/family_members.json
  def create
    @family_member = FamilyMember.new(family_member_params)

    respond_to do |format|
      if @family_member.save
        format.html { redirect_to family_member_path(@family_member), notice: "Family member was successfully created." }
        format.json { render :show, status: :created, location: family_member_path(@family_member) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @family_member.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/family_members/1 or /admin/family_members/1.json
  def update
    respond_to do |format|
      if @family_member.update(family_member_params)
        format.html { redirect_to family_member_path(@family_member), notice: "Family member was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: family_member_path(@family_member) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @family_member.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/family_members/1 or /admin/family_members/1.json
  def destroy
    @family_member.destroy!

    respond_to do |format|
      format.html { redirect_to family_members_path, notice: "Family member was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_family_member
      @family_member = FamilyMember.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def family_member_params
      params.expect(family_member: [ :guardian_id, :mentee_id, :relationship_type ])
    end
end
