# frozen_string_literal: true

require "test_helper"

class CreateRedemptionServiceTest < ActiveSupport::TestCase
  setup do
    # Create Olympic season that includes today
    @olympic_season = OlympicSeason.create!(
      name: "Test Season",
      start_month: 1,
      start_day: 1,
      end_month: 12,
      end_day: 31
    )

    @user = create_mentee_user(email: "mentee@example.com")
    @mentee = @user.mentee
    @admin = create_user(email: "admin@example.com")
    @staff = create_staff_user(email: "staff@example.com")

    @incentive = Incentive.create!(
      name: "Test Incentive",
      description: "Test description",
      point_cost: 100,
      incentive_type: "individual",
      active: true,
      created_by: @admin
    )

    # Give mentee enough points to afford multiple incentives and deductions
    PointLog.create!(
      mentee: @mentee,
      points: 300,
      log_type: "adjustment",
      reason: "Test points",
      created_at: Time.current
    )
  end

  test "successfully creates redemption and sends notification" do
    service = CreateRedemptionService.new(@user)

    assert_difference "Redemption.count", 1 do
      assert_difference "Message.count", 1 do
        result = service.create(incentive_id: @incentive.id)

        assert result.success?
        assert_equal @mentee, result.redemption.mentee
        assert_equal @incentive, result.redemption.incentive
        assert_equal 100, result.redemption.points_spent
        assert_equal "pending", result.redemption.status
        assert_equal [], result.errors

        # Verify notification was sent
        message = Message.last
        assert_equal "New Redemption Request: #{@incentive.name}", message.subject
        assert message.recipients.include?(@admin)
        assert message.recipients.include?(@staff)
        # Message should contain the incentive name and mentee info
        assert message.message.include?(@incentive.name)
      end
    end
  end

  test "fails when user is not a mentee" do
    non_mentee = create_guardian_user(email: "guardian@example.com")
    service = CreateRedemptionService.new(non_mentee)

    assert_no_difference "Redemption.count" do
      assert_no_difference "Message.count" do
        result = service.create(incentive_id: @incentive.id)

        assert_not result.success?
        assert_nil result.redemption
        assert_includes result.errors, "Only mentees can create redemptions"
      end
    end
  end

  test "fails when incentive is not found" do
    service = CreateRedemptionService.new(@user)

    assert_no_difference "Redemption.count" do
      assert_no_difference "Message.count" do
        result = service.create(incentive_id: 999_999)

        assert_not result.success?
        assert_nil result.redemption
        assert_includes result.errors, "Incentive not found or inactive"
      end
    end
  end

  test "fails when incentive is inactive" do
    inactive_incentive = Incentive.create!(
      name: "Inactive Incentive",
      point_cost: 50,
      incentive_type: "individual",
      active: false,
      created_by: @admin
    )
    service = CreateRedemptionService.new(@user)

    assert_no_difference "Redemption.count" do
      assert_no_difference "Message.count" do
        result = service.create(incentive_id: inactive_incentive.id)

        assert_not result.success?
        assert_nil result.redemption
        assert_includes result.errors, "Incentive not found or inactive"
      end
    end
  end

  test "fails when mentee has insufficient points" do
    # Create user with fewer points
    low_points_user = create_mentee_user(email: "lowpoints@example.com")
    low_points_mentee = low_points_user.mentee

    PointLog.create!(
      mentee: low_points_mentee,
      points: 50,
      log_type: "adjustment",
      reason: "Low test points",
      created_at: Time.current
    )

    service = CreateRedemptionService.new(low_points_user)

    assert_no_difference "Redemption.count" do
      assert_no_difference "Message.count" do
        result = service.create(incentive_id: @incentive.id)

        assert_not result.success?
        assert_nil result.redemption
        assert_includes result.errors, "Not enough points (50 available, 100 required)"
      end
    end
  end

  test "fails when mentee has existing pending redemption for same incentive" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: @incentive.point_cost,
      status: "pending"
    )
    service = CreateRedemptionService.new(@user)

    assert_no_difference "Redemption.count" do
      assert_no_difference "Message.count" do
        result = service.create(incentive_id: @incentive.id)

        assert_not result.success?
        assert_nil result.redemption
        assert_includes result.errors, "You already have a pending redemption for this incentive"
      end
    end
  end

  test "allows redemption for previously denied incentive" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: @incentive.point_cost,
      status: "denied"
    )
    service = CreateRedemptionService.new(@user)

    assert_difference "Redemption.count", 1 do
      assert_difference "Message.count", 1 do
        result = service.create(incentive_id: @incentive.id)

        assert result.success?
        assert_equal "pending", result.redemption.status
      end
    end
  end

  test "allows redemption for previously approved incentive" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: @incentive.point_cost,
      status: "approved"
    )
    service = CreateRedemptionService.new(@user)

    assert_difference "Redemption.count", 1 do
      assert_difference "Message.count", 1 do
        result = service.create(incentive_id: @incentive.id)

        assert result.success?
        assert_equal "pending", result.redemption.status
      end
    end
  end
end
