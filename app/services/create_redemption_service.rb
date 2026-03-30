# frozen_string_literal: true

class CreateRedemptionService
  Result = Struct.new(:success?, :redemption, :errors, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def create(incentive_id:)
    mentee = @user.mentee
    return Result.new(success?: false, errors: ["Only mentees can create redemptions"]) unless mentee

    incentive = Incentive.active.find_by(id: incentive_id)
    return Result.new(success?: false, errors: ["Incentive not found or inactive"]) unless incentive

    # Check for existing pending redemption first (business rule)
    existing_pending = mentee.redemptions.pending.find_by(incentive: incentive)
    if existing_pending
      return Result.new(
        success?: false,
        errors: ["You already have a pending redemption for this incentive"]
      )
    end

    unless mentee.can_afford?(incentive.point_cost)
      return Result.new(
        success?: false,
        errors: ["Not enough points (#{mentee.total_points} available, #{incentive.point_cost} required)"]
      )
    end

    redemption = mentee.redemptions.build(
      incentive: incentive,
      points_spent: incentive.point_cost,
      status: "pending"
    )

    if redemption.save
      RedemptionCreatedMessage.new(redemption).deliver
      Result.new(success?: true, redemption: redemption, errors: [])
    else
      Result.new(success?: false, errors: redemption.errors.full_messages)
    end
  end
end
