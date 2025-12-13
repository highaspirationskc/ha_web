# frozen_string_literal: true

require "test_helper"

class GradeCardsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "admin_gc_ctrl@example.com")
    @mentor = create_mentor_user(email: "mentor_gc_ctrl@example.com")
    @mentee_user = create_mentee_user(email: "mentee_gc_ctrl@example.com", mentor: @mentor.mentor)
    @guardian_user = create_guardian_user(email: "guardian_gc_ctrl@example.com")

    @mentee = @mentee_user.mentee
    @guardian = @guardian_user.guardian

    # Link guardian to mentee
    FamilyMember.create!(guardian: @guardian, mentee: @mentee, relationship_type: :parent)

    # Create a medium for grade card
    @medium = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_ctrl_test_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      media_type: "image",
      category: "grade_card"
    )

    # Create a grade card for viewing tests
    @grade_card = GradeCard.create!(
      mentee: @mentee,
      medium: @medium,
      description: "Test grades"
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Index tests - only mentees can access the /grade_cards route

  test "mentee can access grade cards index" do
    login_as(@mentee_user)
    get grade_cards_path
    assert_response :success
    assert_select "h1", "Grade Cards"
  end

  test "mentee sees only their own grade cards" do
    other_mentee = create_mentee_user(email: "other_mentee_gc_ctrl@example.com")
    other_medium = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "other_gc_ctrl_#{SecureRandom.hex(8)}",
      filename: "other_grade_card.jpg",
      media_type: "image",
      category: "grade_card"
    )
    other_grade_card = GradeCard.create!(
      mentee: other_mentee.mentee,
      medium: other_medium,
      description: "Other grades"
    )

    login_as(@mentee_user)
    get grade_cards_path

    assert_response :success
    assert_match @grade_card.description, response.body
    assert_no_match other_grade_card.description, response.body
  end

  test "non-mentee roles cannot access grade cards index" do
    # Admin redirected to dashboard
    login_as(@admin)
    get grade_cards_path
    assert_redirected_to dashboard_path

    # Mentor redirected to dashboard
    login_as(@mentor)
    get grade_cards_path
    assert_redirected_to dashboard_path

    # Guardian redirected to dashboard
    login_as(@guardian_user)
    get grade_cards_path
    assert_redirected_to dashboard_path
  end

  # Create tests - mentee can create for themselves

  test "mentee can create grade card for themselves" do
    login_as(@mentee_user)

    CloudflareImagesService.stubs(:upload).returns({
      cloudflare_id: "new_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      content_type: "image/jpeg"
    })

    file = fixture_file_upload("test/fixtures/files/test_image.jpg", "image/jpeg")

    assert_difference ["GradeCard.count", "Medium.count"], 1 do
      post grade_cards_path, params: {
        file: file,
        description: "My Fall 2025 grades"
      }
    end

    assert_redirected_to grade_cards_path
    assert_match "Grade card added", flash[:notice]
  end

  test "create grade card requires file" do
    login_as(@mentee_user)

    assert_no_difference ["GradeCard.count", "Medium.count"] do
      post grade_cards_path, params: {
        description: "Missing file"
      }
    end

    assert_redirected_to grade_cards_path
    assert_match "select a file", flash[:alert]
  end

  # Mentees cannot delete grade cards (only staff/admin can, via users/:id page)

  test "mentee cannot delete grade cards" do
    login_as(@mentee_user)

    assert_no_difference "GradeCard.count" do
      delete grade_card_path(@grade_card)
    end

    assert_redirected_to grade_cards_path
    assert_match "permission", flash[:alert]
  end

  test "requires authentication" do
    get grade_cards_path
    assert_redirected_to root_path
  end
end
