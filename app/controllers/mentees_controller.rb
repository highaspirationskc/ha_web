class MenteesController < ApplicationController
  before_action { require_navigation_access(:mentees) }
  before_action :require_mentor
  before_action :set_mentee, only: [:show, :destroy]

  def index
    @mentees = current_user.mentor.mentees.includes(:user, :team).order("users.last_name, users.first_name")
    @available_mentees = Mentee.where(mentor_id: nil).includes(:user, :team).order("users.last_name, users.first_name")
  end

  def show
    @total_points = @mentee.user.total_points
  end

  def create
    mentee = Mentee.find_by(id: params[:mentee_id])

    if mentee.nil?
      redirect_to mentees_path, alert: "Mentee not found"
      return
    end

    if mentee.mentor_id.present?
      redirect_to mentees_path, alert: "Mentee is already assigned to a mentor"
      return
    end

    if mentee.update(mentor: current_user.mentor)
      redirect_to mentees_path, notice: "#{mentee.user.first_name} #{mentee.user.last_name} has been added to your mentees"
    else
      redirect_to mentees_path, alert: "Could not assign mentee"
    end
  end

  def destroy
    name = "#{@mentee.user.first_name} #{@mentee.user.last_name}"
    if @mentee.update(mentor: nil)
      redirect_to mentees_path, notice: "#{name} has been removed from your mentees"
    else
      redirect_to mentees_path, alert: "Could not remove mentee"
    end
  end

  private

  def require_mentor
    unless current_user.mentor.present?
      redirect_to dashboard_path, alert: "You must be a mentor to access this page"
    end
  end

  def set_mentee
    @mentee = current_user.mentor.mentees.find_by(id: params[:id])
    unless @mentee
      redirect_to mentees_path, alert: "Mentee not found"
    end
  end
end
