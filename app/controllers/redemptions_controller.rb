class RedemptionsController < ApplicationController
  include Authentication

  before_action { require_navigation_access(:rewards) }
  before_action :set_mentee
  before_action :set_incentive, only: [:create]

  def create
    result = CreateRedemptionService.new(current_user).create(incentive_id: @incentive.id)

    if result.success?
      redirect_to rewards_path(tab: "my-redemptions"), notice: "Redemption request submitted! Awaiting approval."
    else
      # Map service errors to appropriate flash messages
      error_message = result.errors.first

      if error_message == "Incentive not found or inactive"
        redirect_to rewards_path(tab: params[:tab] || "individual"), alert: "This incentive is no longer available."
      elsif error_message&.start_with?("Not enough points")
        redirect_to rewards_path(tab: params[:tab] || "individual"), alert: "Insufficient points. You need #{@incentive.point_cost} points but only have #{@mentee.total_points}."
      elsif error_message == "You already have a pending redemption for this incentive"
        redirect_to rewards_path(tab: "my-redemptions"), notice: "You already have a pending redemption for this incentive."
      else
        redirect_to rewards_path(tab: params[:tab] || "individual"), alert: "Could not create redemption: #{error_message}"
      end
    end
  end

  private

  def set_mentee
    @mentee = current_user.mentee
    unless @mentee
      render plain: "User is not a mentee", status: :forbidden
    end
  end

  def set_incentive
    @incentive = Incentive.find_by(id: params[:incentive_id])
    unless @incentive
      redirect_to rewards_path, alert: "Incentive not found."
    end
  end
end
