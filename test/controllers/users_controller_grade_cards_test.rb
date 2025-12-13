# frozen_string_literal: true

require "test_helper"

class UsersControllerGradeCardsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "admin_gc@example.com")
    @staff = create_staff_user(email: "staff_gc@example.com")
    @mentor = create_mentor_user(email: "mentor_gc@example.com")
    @mentee_user = create_mentee_user(email: "mentee_gc@example.com", mentor: @mentor.mentor)
    @guardian_user = create_guardian_user(email: "guardian_gc@example.com")
    @volunteer = create_volunteer_user(email: "volunteer_gc@example.com")

    @mentee = @mentee_user.mentee
    @guardian = @guardian_user.guardian

    # Link guardian to mentee
    FamilyMember.create!(guardian: @guardian, mentee: @mentee, relationship_type: :parent)

    # Create a medium for grade card
    @medium = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_test_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      media_type: "image",
      category: "grade_card"
    )

    # Create a grade card for delete tests
    @grade_card = GradeCard.create!(
      mentee: @mentee,
      medium: @medium,
      description: "Test grades"
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # add_grade_card tests

  test "admin can add grade card for mentee" do
    login_as(@admin)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_difference ["GradeCard.count", "Medium.count"], 1 do
      post add_grade_card_user_path(@mentee_user), params: {
        file: file,
        description: "Fall 2025 grades"
      }
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "Grade card added", flash[:notice]
  end

  test "staff can add grade card for mentee" do
    login_as(@staff)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_difference ["GradeCard.count", "Medium.count"], 1 do
      post add_grade_card_user_path(@mentee_user), params: {
        file: file,
        description: "Spring 2025 grades"
      }
    end

    assert_redirected_to user_path(@mentee_user)
  end

  test "mentor can add grade card for their mentee" do
    login_as(@mentor)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_difference ["GradeCard.count", "Medium.count"], 1 do
      post add_grade_card_user_path(@mentee_user), params: {
        file: file,
        description: "Mentor uploaded grades"
      }
    end

    assert_redirected_to user_path(@mentee_user)
  end

  test "mentee can add grade card for themselves" do
    login_as(@mentee_user)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_difference ["GradeCard.count", "Medium.count"], 1 do
      post add_grade_card_user_path(@mentee_user), params: {
        file: file,
        description: "My grades"
      }
    end

    assert_redirected_to user_path(@mentee_user)
  end

  test "guardian can add grade card for their child" do
    login_as(@guardian_user)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_difference ["GradeCard.count", "Medium.count"], 1 do
      post add_grade_card_user_path(@mentee_user), params: {
        file: file,
        description: "Guardian uploaded grades"
      }
    end

    assert_redirected_to user_path(@mentee_user)
  end

  test "mentor cannot add grade card for other mentees" do
    other_mentee_user = create_mentee_user(email: "other_mentee_gc@example.com")
    login_as(@mentor)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_no_difference ["GradeCard.count", "Medium.count"] do
      post add_grade_card_user_path(other_mentee_user), params: {
        file: file,
        description: "Unauthorized grades"
      }
    end

    # Mentor can't manage other mentees, redirects to users_path
    assert_redirected_to users_path
    assert_match "permission", flash[:alert]
  end

  test "volunteer cannot login to add grade cards" do
    # Volunteers don't have can_login? permission, so they can't even attempt to add grade cards
    # This is handled at the session level - volunteers cannot log into the web app
    @volunteer.reload
    assert @volunteer.active?, "Volunteer should be active"
    assert @volunteer.volunteer.present?, "Volunteer should have volunteer role"
    assert_not @volunteer.can_login?, "Volunteers should not be able to login"

    # Attempt to login as volunteer - should fail with 401
    post login_path, params: { email: @volunteer.email, password: "Password123!" }
    assert_response :unauthorized
    assert_match "permission", flash[:alert]
  end

  test "cannot add grade card to non-mentee user" do
    login_as(@admin)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_no_difference ["GradeCard.count", "Medium.count"] do
      post add_grade_card_user_path(@volunteer), params: {
        file: file,
        description: "Invalid target"
      }
    end

    assert_redirected_to user_path(@volunteer)
    assert_match "only add grade cards to mentees", flash[:alert]
  end

  test "add grade card requires file" do
    login_as(@admin)

    assert_no_difference ["GradeCard.count", "Medium.count"] do
      post add_grade_card_user_path(@mentee_user), params: {
        description: "Missing file"
      }
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "select a file", flash[:alert]
  end

  test "add grade card requires authentication" do
    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_no_difference ["GradeCard.count", "Medium.count"] do
      post add_grade_card_user_path(@mentee_user), params: {
        file: file,
        description: "Unauthenticated"
      }
    end

    assert_redirected_to root_path
  end

  # remove_grade_card tests

  test "admin can remove grade card" do
    login_as(@admin)
    CloudflareImagesService.stubs(:delete).returns(true)

    assert_difference "GradeCard.count", -1 do
      delete remove_grade_card_user_path(@mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "Grade card removed", flash[:notice]
  end

  test "staff can remove grade card" do
    login_as(@staff)
    CloudflareImagesService.stubs(:delete).returns(true)

    assert_difference "GradeCard.count", -1 do
      delete remove_grade_card_user_path(@mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to user_path(@mentee_user)
  end

  test "mentor cannot remove grade cards" do
    login_as(@mentor)

    assert_no_difference "GradeCard.count" do
      delete remove_grade_card_user_path(@mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "permission", flash[:alert]
  end

  test "mentee cannot remove grade cards from their own profile" do
    login_as(@mentee_user)

    assert_no_difference "GradeCard.count" do
      delete remove_grade_card_user_path(@mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "permission", flash[:alert]
  end

  test "guardian cannot remove grade cards" do
    login_as(@guardian_user)

    assert_no_difference "GradeCard.count" do
      delete remove_grade_card_user_path(@mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "permission", flash[:alert]
  end

  test "remove grade card requires authentication" do
    assert_no_difference "GradeCard.count" do
      delete remove_grade_card_user_path(@mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to root_path
  end

  test "cannot remove grade card that does not exist" do
    login_as(@admin)

    delete remove_grade_card_user_path(@mentee_user), params: {
      grade_card_id: 999999
    }

    assert_redirected_to user_path(@mentee_user)
    assert_match "Grade card not found", flash[:alert]
  end

  test "cannot remove grade card from another mentee" do
    other_mentee_user = create_mentee_user(email: "other_mentee2_gc@example.com")
    login_as(@admin)

    assert_no_difference "GradeCard.count" do
      delete remove_grade_card_user_path(other_mentee_user), params: {
        grade_card_id: @grade_card.id
      }
    end

    assert_redirected_to user_path(other_mentee_user)
    assert_match "Grade card not found", flash[:alert]
  end
end
