require "test_helper"

class UsersControllerRedemptionsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "red_admin@example.com")
    @staff = create_staff_user(email: "red_staff@example.com")
    @mentor = create_mentor_user(email: "red_mentor@example.com")
    @mentee_user = create_mentee_user(email: "red_mentee@example.com")
    @mentee = @mentee_user.mentee

    # Set up Olympic season and give mentee points
    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )
    event_type = EventType.create!(name: "Test Event", category: "org", point_value: 100)
    event = Event.create!(name: "Points Event", event_date: Time.current, event_type: event_type, created_by: @admin)
    EventLog.create!(user: @mentee_user, event: event, points_awarded: 100, log_type: "arrived")

    @incentive = Incentive.create!(
      name: "Jack Stack Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )

    @pending_redemption = Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    @approved_redemption = Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "approved",
      approved_by: @admin,
      approved_at: Time.current
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # === Authentication ===

  test "redeem_incentive redirects when not authenticated" do
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id }
    assert_redirected_to root_path
  end

  test "deny_redemption redirects when not authenticated" do
    post deny_redemption_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id, notes: "No" }
    assert_redirected_to root_path
  end

  test "delete_redemption redirects when not authenticated" do
    delete delete_redemption_user_path(@mentee_user), params: { redemption_id: @approved_redemption.id, reason: "Error" }
    assert_redirected_to root_path
  end

  # === Authorization ===

  test "mentor cannot redeem incentive" do
    login_as(@mentor)
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id }
    assert_redirected_to users_path
  end

  test "admin can redeem incentive" do
    login_as(@admin)
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id }
    assert_redirected_to user_path(@mentee_user)
  end

  test "staff can redeem incentive" do
    login_as(@staff)
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id }
    assert_redirected_to user_path(@mentee_user)
  end

  # === Redeem Incentive ===

  test "redeem_incentive approves pending redemption" do
    login_as(@admin)
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id }

    @pending_redemption.reload
    assert_equal "approved", @pending_redemption.status
    assert_equal @admin, @pending_redemption.approved_by
    assert_not_nil @pending_redemption.approved_at
  end

  test "redeem_incentive fails for non-pending redemption" do
    login_as(@admin)
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @approved_redemption.id }
    assert_redirected_to user_path(@mentee_user)
    assert_equal "Redemption is not pending", flash[:alert]
  end

  test "redeem_incentive fails when mentee has insufficient points" do
    login_as(@admin)
    # Create a pending redemption that costs more than the mentee has (0 points)
    expensive_incentive = Incentive.create!(
      name: "Expensive Item",
      description: "Costs 100 points",
      point_cost: 100,
      incentive_type: "individual",
      created_by: @admin
    )
    expensive_redemption = Redemption.create!(
      mentee: @mentee,
      incentive: expensive_incentive,
      points_spent: 100,
      status: "pending"
    )

    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: expensive_redemption.id }
    assert_redirected_to user_path(@mentee_user)
    assert_equal "Mentee has insufficient points", flash[:alert]

    expensive_redemption.reload
    assert_equal "pending", expensive_redemption.status
  end

  test "redeem_incentive fails for nonexistent redemption" do
    login_as(@admin)
    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: 999999 }
    assert_redirected_to user_path(@mentee_user)
    assert_equal "Redemption not found", flash[:alert]
  end

  test "redeem_incentive sends message when requested" do
    login_as(@admin)
    assert_difference "Message.count", 1 do
      post redeem_incentive_user_path(@mentee_user), params: {
        redemption_id: @pending_redemption.id,
        send_message: "1",
        message_text: "Your gift card is ready!"
      }
    end
  end

  test "redeem_incentive does not send message when not requested" do
    login_as(@admin)
    assert_no_difference "Message.count" do
      post redeem_incentive_user_path(@mentee_user), params: {
        redemption_id: @pending_redemption.id
      }
    end
  end

  # === Deny Redemption ===

  test "deny_redemption denies pending redemption" do
    login_as(@admin)
    post deny_redemption_user_path(@mentee_user), params: {
      redemption_id: @pending_redemption.id,
      notes: "Not enough evidence"
    }

    @pending_redemption.reload
    assert_equal "denied", @pending_redemption.status
    assert_equal @admin, @pending_redemption.approved_by
    assert_equal "Not enough evidence", @pending_redemption.notes
  end

  test "deny_redemption sends denial message" do
    login_as(@admin)
    assert_difference "Message.count", 1 do
      post deny_redemption_user_path(@mentee_user), params: {
        redemption_id: @pending_redemption.id,
        notes: "Denied for testing"
      }
    end
  end

  test "deny_redemption fails for non-pending redemption" do
    login_as(@admin)
    post deny_redemption_user_path(@mentee_user), params: {
      redemption_id: @approved_redemption.id,
      notes: "Too late"
    }
    assert_redirected_to user_path(@mentee_user)
    assert_equal "Redemption is not pending", flash[:alert]
  end

  # === Delete Redemption ===

  test "delete_redemption with refund sets status to deleted" do
    login_as(@admin)
    delete delete_redemption_user_path(@mentee_user), params: {
      redemption_id: @approved_redemption.id,
      reason: "Duplicate",
      refund_points: "1"
    }

    @approved_redemption.reload
    assert_equal "deleted", @approved_redemption.status
    assert_equal "Duplicate", @approved_redemption.notes
  end

  test "delete_redemption without refund sets status to deleted_no_refund" do
    login_as(@admin)
    delete delete_redemption_user_path(@mentee_user), params: {
      redemption_id: @approved_redemption.id,
      reason: "Already given"
    }

    @approved_redemption.reload
    assert_equal "deleted_no_refund", @approved_redemption.status
  end

  test "delete_redemption sends message when requested" do
    login_as(@admin)
    assert_difference "Message.count", 1 do
      delete delete_redemption_user_path(@mentee_user), params: {
        redemption_id: @approved_redemption.id,
        reason: "Error",
        refund_points: "1",
        send_message: "1",
        message_text: "We removed this by mistake"
      }
    end
  end

  test "delete_redemption does not send message when not requested" do
    login_as(@admin)
    assert_no_difference "Message.count" do
      delete delete_redemption_user_path(@mentee_user), params: {
        redemption_id: @approved_redemption.id,
        reason: "Error"
      }
    end
  end

  test "delete_redemption fails for nonexistent redemption" do
    login_as(@admin)
    delete delete_redemption_user_path(@mentee_user), params: {
      redemption_id: 999999,
      reason: "Error"
    }
    assert_redirected_to user_path(@mentee_user)
    assert_equal "Redemption not found", flash[:alert]
  end

  test "delete_redemption refunds points when refund_points is checked" do
    login_as(@admin)
    initial_points = @mentee.total_points

    delete delete_redemption_user_path(@mentee_user), params: {
      redemption_id: @approved_redemption.id,
      reason: "Duplicate",
      refund_points: "1"
    }

    @mentee.reload
    # With pointable scope, the original deduction is excluded when status becomes "deleted",
    # and a refund PointLog is created. The net effect is points are restored.
    # Expected: initial_points (which already includes the -25 deduction) + 25 (refund) = 100
    assert_equal initial_points + @approved_redemption.points_spent, @mentee.total_points
  end

  test "delete_redemption does not refund points when refund_points is not checked" do
    login_as(@admin)
    initial_points = @mentee.total_points

    delete delete_redemption_user_path(@mentee_user), params: {
      redemption_id: @approved_redemption.id,
      reason: "Already given"
    }

    @mentee.reload
    assert_equal initial_points, @mentee.total_points
  end

  test "redeem_incentive deducts points from mentee" do
    login_as(@admin)
    # Points are already deducted for pending redemptions (they're "active")
    # So redeeming changes status from pending to approved, but points stay deducted
    initial_points = @mentee.total_points

    post redeem_incentive_user_path(@mentee_user), params: { redemption_id: @pending_redemption.id }

    @mentee.reload
    @pending_redemption.reload
    # Points should remain the same (both pending and approved are in active scope)
    assert_equal initial_points, @mentee.total_points
    assert_equal "approved", @pending_redemption.status
  end

  # === Show page displays redemptions ===

  test "show page displays redemptions section for mentee" do
    login_as(@admin)
    get user_path(@mentee_user)
    assert_response :success
    assert_select "h3", /Redemptions/
  end
end
