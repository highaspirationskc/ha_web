class RedemptionsController < ApplicationController
  include Authentication

  before_action { require_navigation_access(:rewards) }
  before_action :set_mentee
  before_action :set_incentive, only: [:create]

  def create
    # Check if incentive is active
    unless @incentive.active?
      redirect_to rewards_path(tab: params[:tab] || "individual"), alert: "This incentive is no longer available."
      return
    end

    # Check if mentee can afford it
    unless @mentee.can_afford?(@incentive.point_cost)
      redirect_to rewards_path(tab: params[:tab] || "individual"), alert: "Insufficient points. You need #{@incentive.point_cost} points but only have #{@mentee.total_points}."
      return
    end

    # Check for existing pending redemption for same incentive
    existing_pending = @mentee.redemptions.pending.find_by(incentive: @incentive)
    if existing_pending
      redirect_to rewards_path(tab: "my-redemptions"), notice: "You already have a pending redemption for this incentive."
      return
    end

    # Create the redemption
    @redemption = @mentee.redemptions.new(
      incentive: @incentive,
      points_spent: @incentive.point_cost,
      status: "pending"
    )

    if @redemption.save
      # Notify staff
      RedemptionCreatedMessage.new(@redemption).deliver

      redirect_to rewards_path(tab: "my-redemptions"), notice: "Redemption request submitted! Awaiting approval."
    else
      redirect_to rewards_path(tab: params[:tab] || "individual"), alert: "Could not create redemption: #{@redemption.errors.full_messages.join(", ")}"
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
