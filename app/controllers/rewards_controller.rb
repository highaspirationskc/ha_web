class RewardsController < ApplicationController
  include Authentication

  before_action { require_navigation_access(:rewards) }
  before_action :set_mentee

  def index
    @individual_incentives = Incentive.where(incentive_type: "individual", active: true)
    @team_incentives = Incentive.where(incentive_type: "team", active: true)
    @redemptions = @mentee.redemptions.order(created_at: :desc)
    @total_points = @mentee.total_points
  end

  private

  def set_mentee
    @mentee = current_user.mentee
    unless @mentee
      render plain: "User is not a mentee", status: :forbidden
    end
  end
end
