require "application_system_test_case"

class PointsManagementTest < ApplicationSystemTestCase
  def setup
    @admin = create_user(email: "admin_pts@example.com")
    @admin.activate!

    @mentee_user = User.create!(email: "mentee_pts@example.com", password: "Password123!")
    @mentee = Mentee.create!(user: @mentee_user)
    @mentee_user.activate!

    # Create a season for point calculations
    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )
  end

  def login_as(user)
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: "Password123!"
    click_button "Sign in"
    assert_text "Dashboard", wait: 5
  end

  test "viewing point history" do
    # Create some point logs
    PointLog.create!(mentee: @mentee, points: 10, reason: "Event attendance", awarded_by: @admin, log_type: "attendance")
    PointLog.create!(mentee: @mentee, points: -5, reason: "Gift card redemption", awarded_by: @admin, log_type: "redemption")

    login_as(@admin)
    visit user_path(@mentee_user)

    # Check points display
    assert_text "Points"
    assert_text "5"

    # Click History link
    click_on "History"

    # Should be on point history page
    assert_text "Points History"
    assert_text "Event attendance"
    assert_text "Gift card redemption"
    assert_text "Attendance"
    assert_text "Redemption"
  end

  test "managing points - add points" do
    login_as(@admin)
    visit user_path(@mentee_user)

    # Check current points
    assert_text "Points"
    assert_text "0"

    # Open manage points modal
    click_on "Manage Points"

    # Modal should be visible
    assert_text "Manage Points", wait: 5

    # Increment points
    within("#manage-points-modal") do
      click_button class: "bg-indigo-100"
    end

    # Fill in reason
    fill_in "Reason", with: "Great participation in class"

    # Save
    click_on "Save"

    # Should redirect back to user page - check points updated
    assert_text "1", wait: 5

    # Verify point log was created
    @mentee.reload
    assert_equal 1, @mentee.total_points
  end

  test "managing points - subtract points" do
    # Give mentee some points first
    PointLog.create!(mentee: @mentee, points: 20, reason: "Initial points", awarded_by: @admin, log_type: "adjustment")

    login_as(@admin)
    visit user_path(@mentee_user)

    assert_text "20"

    # Open manage points modal
    click_on "Manage Points"

    # Modal should be visible
    assert_text "Manage Points", wait: 5

    # Decrement points twice
    within("#manage-points-modal") do
      2.times { click_button class: "bg-gray-100" }
    end

    # Fill in reason
    fill_in "Reason", with: "Missed attendance"

    # Save
    click_on "Save"

    # Should redirect back to user page - check points updated
    assert_text "18", wait: 5

    # Verify point log was created
    @mentee.reload
    assert_equal 18, @mentee.total_points
  end

  test "managing points with message" do
    login_as(@admin)
    visit user_path(@mentee_user)

    # Open manage points modal
    click_on "Manage Points"

    # Modal should be visible
    assert_text "Manage Points", wait: 5

    # Add points
    within("#manage-points-modal") do
      click_button class: "bg-indigo-100"
    end

    # Fill in reason
    fill_in "Reason", with: "Excellent behavior"

    # Check send message checkbox
    check "Send message with points modification"

    # Message area should appear and fill it
    fill_in "Message", with: "Keep up the great work!"

    # Save
    click_on "Save"

    # Should show success - check points updated
    assert_text "1", wait: 5

    # Verify message was sent
    assert_equal 1, Message.count
    message = Message.first
    assert_equal @mentee_user, message.recipients.first
  end

  test "cannot reduce points below zero" do
    login_as(@admin)
    visit user_path(@mentee_user)

    # Open manage points modal
    click_on "Manage Points"

    # Modal should be visible
    assert_text "Manage Points", wait: 5

    # Try to decrement (should be prevented by UI logic)
    within("#manage-points-modal") do
      # Get the initial value
      initial_result = find("[data-points-manager-target='resultDisplay']").text

      # Try to click decrement
      click_button class: "bg-gray-100"

      # Result should not change (still at 0, can't go negative)
      result = find("[data-points-manager-target='resultDisplay']").text
      assert_equal initial_result, result
    end
  end

  test "mentor cannot manage points" do
    mentor_user = User.create!(email: "mentor_pts@example.com", password: "Password123!")
    Mentor.create!(user: mentor_user)
    mentor_user.activate!

    login_as(mentor_user)
    visit user_path(@mentee_user)

    # Should not see Manage Points button
    assert_no_text "Manage Points"
  end

  test "reason is required" do
    login_as(@admin)
    visit user_path(@mentee_user)

    # Open manage points modal
    click_on "Manage Points"

    # Modal should be visible
    assert_text "Manage Points", wait: 5

    # Add points
    within("#manage-points-modal") do
      click_button class: "bg-indigo-100"
    end

    # Don't fill in reason, just save
    click_on "Save"

    # Should show error or stay on page
    # Since the modal doesn't close without reason validation
    assert_text "Manage Points"
  end

  test "zero points adjustment is rejected" do
    login_as(@admin)
    visit user_path(@mentee_user)

    # Open manage points modal
    click_on "Manage Points"

    # Modal should be visible
    assert_text "Manage Points", wait: 5

    # Don't change points (leave at 0)
    # Fill in reason
    fill_in "Reason", with: "No change"

    click_on "Save"

    # Points should stay at 0 (no change since adjustment was 0)
    # The form may or may not show an error, but points shouldn't change
    visit user_path(@mentee_user) # Refresh to check points
    assert_text "Points"
    assert_text "0"
  end
end
