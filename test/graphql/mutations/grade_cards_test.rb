# frozen_string_literal: true

require "test_helper"

class GradeCardsMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin_gc@example.com")
    @staff = create_staff_user(email: "staff_gc@example.com")
    @mentor = create_mentor_user(email: "mentor_gc@example.com")
    @mentee_user = create_mentee_user(email: "mentee_gc@example.com", mentor: @mentor.mentor)
    @guardian_user = create_guardian_user(email: "guardian_gc@example.com")

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
  end

  # CreateGradeCard tests

  test "admin can create grade card for any mentee" do
    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
            description
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s,
        description: "Fall 2025 grades"
      }
    }, context: { current_user: @admin })

    grade_card = result.dig("data", "createGradeCard", "gradeCard")
    errors = result.dig("data", "createGradeCard", "errors")

    assert_not_nil grade_card
    assert_equal "Fall 2025 grades", grade_card["description"]
    assert_empty errors
  end

  test "staff can create grade card for any mentee" do
    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
            description
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s,
        description: "Spring 2025 grades"
      }
    }, context: { current_user: @staff })

    grade_card = result.dig("data", "createGradeCard", "gradeCard")
    errors = result.dig("data", "createGradeCard", "errors")

    assert_not_nil grade_card
    assert_empty errors
  end

  test "mentee can create grade card for themselves" do
    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s
      }
    }, context: { current_user: @mentee_user })

    grade_card = result.dig("data", "createGradeCard", "gradeCard")
    errors = result.dig("data", "createGradeCard", "errors")

    assert_not_nil grade_card
    assert_empty errors
  end

  test "mentor can create grade card for their mentee" do
    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s
      }
    }, context: { current_user: @mentor })

    grade_card = result.dig("data", "createGradeCard", "gradeCard")
    errors = result.dig("data", "createGradeCard", "errors")

    assert_not_nil grade_card
    assert_empty errors
  end

  test "guardian can create grade card for their child" do
    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s
      }
    }, context: { current_user: @guardian_user })

    grade_card = result.dig("data", "createGradeCard", "gradeCard")
    errors = result.dig("data", "createGradeCard", "errors")

    assert_not_nil grade_card
    assert_empty errors
  end

  test "mentor cannot create grade card for other mentees" do
    other_mentee_user = create_mentee_user(email: "other_mentee_gc@example.com")
    other_mentee = other_mentee_user.mentee

    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: other_mentee.id.to_s,
        mediumId: @medium.id.to_s
      }
    }, context: { current_user: @mentor })

    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "permission"
  end

  test "volunteer cannot create grade cards" do
    volunteer = create_volunteer_user(email: "volunteer_gc@example.com")

    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s
      }
    }, context: { current_user: volunteer })

    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "permission"
  end

  # DeleteGradeCard tests

  test "admin can delete grade card" do
    grade_card = GradeCard.create!(mentee: @mentee, medium: @medium)

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteGradeCard(id: $id) {
          success
          errors
        }
      }
    GQL

    CloudflareImagesService.stubs(:delete).returns(true)

    result = execute_graphql(mutation, variables: {
      id: grade_card.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteGradeCard", "success")
    errors = result.dig("data", "deleteGradeCard", "errors")

    assert success
    assert_empty errors
    assert_nil GradeCard.find_by(id: grade_card.id)
  end

  test "staff can delete grade card" do
    medium2 = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_test2_#{SecureRandom.hex(8)}",
      filename: "grade_card2.jpg",
      media_type: "image",
      category: "grade_card"
    )
    grade_card = GradeCard.create!(mentee: @mentee, medium: medium2)

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteGradeCard(id: $id) {
          success
          errors
        }
      }
    GQL

    CloudflareImagesService.stubs(:delete).returns(true)

    result = execute_graphql(mutation, variables: {
      id: grade_card.id.to_s
    }, context: { current_user: @staff })

    success = result.dig("data", "deleteGradeCard", "success")
    errors = result.dig("data", "deleteGradeCard", "errors")

    assert success
    assert_empty errors
  end

  test "mentor cannot delete grade cards" do
    medium3 = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_test3_#{SecureRandom.hex(8)}",
      filename: "grade_card3.jpg",
      media_type: "image",
      category: "grade_card"
    )
    grade_card = GradeCard.create!(mentee: @mentee, medium: medium3)

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteGradeCard(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: grade_card.id.to_s
    }, context: { current_user: @mentor })

    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "permission"
  end

  test "mentee cannot delete grade cards" do
    medium4 = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_test4_#{SecureRandom.hex(8)}",
      filename: "grade_card4.jpg",
      media_type: "image",
      category: "grade_card"
    )
    grade_card = GradeCard.create!(mentee: @mentee, medium: medium4)

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteGradeCard(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: grade_card.id.to_s
    }, context: { current_user: @mentee_user })

    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "permission"
  end

  # Authentication tests

  test "create grade card requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateGradeCardInput!) {
        createGradeCard(input: $input) {
          gradeCard {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        menteeId: @mentee.id.to_s,
        mediumId: @medium.id.to_s
      }
    }, context: {})

    assert_nil result.dig("data", "createGradeCard")
    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
