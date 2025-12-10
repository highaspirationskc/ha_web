require "test_helper"

class CommunityServiceRecordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Admin user
    @admin_user = User.create!(email: "admin@example.com", password: "Password123!")
    Staff.create!(user: @admin_user, permission_level: :admin)
    @admin_user.activate!

    # Staff user
    @staff_user = User.create!(email: "staff@example.com", password: "Password123!")
    Staff.create!(user: @staff_user, permission_level: :standard)
    @staff_user.activate!

    # Mentor user
    @mentor_user = User.create!(email: "mentor@example.com", password: "Password123!")
    @mentor = Mentor.create!(user: @mentor_user)
    @mentor_user.activate!

    # Mentee user (with mentor)
    @mentee_user = User.create!(email: "mentee@example.com", password: "Password123!")
    @mentee = Mentee.create!(user: @mentee_user, mentor: @mentor)
    @mentee_user.activate!

    # Another mentee (without this mentor)
    @other_mentee_user = User.create!(email: "other_mentee@example.com", password: "Password123!")
    @other_mentee = Mentee.create!(user: @other_mentee_user)
    @other_mentee_user.activate!

    # Create records
    @record = CommunityServiceRecord.create!(
      mentee: @mentee,
      event: "Helped neighbor",
      description: "Mowed their lawn",
      event_date: Date.current,
      hours: 2.5
    )

    @other_record = CommunityServiceRecord.create!(
      mentee: @other_mentee,
      event: "Volunteered",
      description: "Food bank",
      event_date: Date.current,
      hours: 4.0
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Authentication tests
  test "index requires authentication" do
    get community_service_records_path
    assert_redirected_to root_path
  end

  test "show requires authentication" do
    get community_service_record_path(@record)
    assert_redirected_to root_path
  end

  test "new requires authentication" do
    get new_community_service_record_path
    assert_redirected_to root_path
  end

  test "create requires authentication" do
    post community_service_records_path, params: { community_service_record: { event: "Test" } }
    assert_redirected_to root_path
  end

  # Index - role-based visibility
  test "admin sees all records" do
    login_as(@admin_user)
    get community_service_records_path
    assert_response :success
    assert_select "tbody tr", count: 2
  end

  test "staff sees all records" do
    login_as(@staff_user)
    get community_service_records_path
    assert_response :success
    assert_select "tbody tr", count: 2
  end

  test "mentor sees only their mentees records" do
    login_as(@mentor_user)
    get community_service_records_path
    assert_response :success
    assert_select "tbody tr", count: 1
  end

  test "mentee can access community service index and sees own records" do
    login_as(@mentee_user)
    get community_service_records_path
    assert_response :success
    assert_select "tbody tr", count: 1
  end

  # Show
  test "admin can view any record" do
    login_as(@admin_user)
    get community_service_record_path(@other_record)
    assert_response :success
  end

  test "mentor can view their mentees records" do
    login_as(@mentor_user)
    get community_service_record_path(@record)
    assert_response :success
  end

  test "mentee can view own records via community service section" do
    login_as(@mentee_user)
    get community_service_record_path(@record)
    assert_response :success
  end

  # Create - mentees can create their own records
  test "mentee can access new record form" do
    login_as(@mentee_user)
    get new_community_service_record_path
    assert_response :success
  end

  test "mentee can create record" do
    login_as(@mentee_user)
    assert_difference "CommunityServiceRecord.count", 1 do
      post community_service_records_path, params: {
        community_service_record: {
          event: "New event",
          description: "Did something nice",
          event_date: Date.current,
          hours: 1.5
        }
      }
    end
    assert_redirected_to community_service_records_path
  end

  test "mentor can create records for their mentees" do
    login_as(@mentor_user)
    get new_community_service_record_path
    assert_response :success
    assert_select "select[name='community_service_record[mentee_id]']"

    assert_difference "CommunityServiceRecord.count", 1 do
      post community_service_records_path, params: {
        community_service_record: {
          mentee_id: @mentee.id,
          event: "Mentor created event",
          description: "Created by mentor",
          event_date: Date.current,
          hours: 3.0
        }
      }
    end
    assert_redirected_to community_service_records_path
  end

  test "mentor cannot create records for other mentors mentees" do
    login_as(@mentor_user)
    assert_no_difference "CommunityServiceRecord.count" do
      post community_service_records_path, params: {
        community_service_record: {
          mentee_id: @other_mentee.id,
          event: "Invalid event",
          event_date: Date.current,
          hours: 1.0
        }
      }
    end
    assert_redirected_to community_service_records_path
    assert_equal "Invalid mentee selected", flash[:alert]
  end

  # Edit/Update
  test "staff can edit any record" do
    login_as(@staff_user)
    get edit_community_service_record_path(@record)
    assert_response :success

    patch community_service_record_path(@record), params: {
      community_service_record: { approved: false }
    }
    assert_redirected_to community_service_records_path
    @record.reload
    assert_not @record.approved?
  end

  test "mentor can edit their mentees records" do
    login_as(@mentor_user)
    get edit_community_service_record_path(@record)
    assert_response :success

    patch community_service_record_path(@record), params: {
      community_service_record: { approved: false }
    }
    assert_redirected_to community_service_records_path
    @record.reload
    assert_not @record.approved?
  end

  test "mentor cannot edit other mentees records" do
    login_as(@mentor_user)
    get edit_community_service_record_path(@other_record)
    assert_redirected_to community_service_records_path
  end

  test "mentee can edit approved records via community service section" do
    login_as(@mentee_user)
    get edit_community_service_record_path(@record)
    assert_response :success
  end

  test "mentee can update approved records via community service section" do
    login_as(@mentee_user)
    patch community_service_record_path(@record), params: {
      community_service_record: { event: "Updated by mentee", hours: 5.0 }
    }
    assert_redirected_to community_service_records_path
    @record.reload
    assert_equal "Updated by mentee", @record.event
  end

  # Delete
  test "admin can delete records" do
    login_as(@admin_user)
    assert_difference "CommunityServiceRecord.count", -1 do
      delete community_service_record_path(@record)
    end
    assert_redirected_to community_service_records_path
  end

  test "staff can delete records" do
    login_as(@staff_user)
    assert_difference "CommunityServiceRecord.count", -1 do
      delete community_service_record_path(@record)
    end
    assert_redirected_to community_service_records_path
  end

  test "mentor can delete their mentees records" do
    login_as(@mentor_user)
    assert_difference "CommunityServiceRecord.count", -1 do
      delete community_service_record_path(@record)
    end
    assert_redirected_to community_service_records_path
  end

  test "mentor cannot delete other mentees records" do
    login_as(@mentor_user)
    assert_no_difference "CommunityServiceRecord.count" do
      delete community_service_record_path(@other_record)
    end
    assert_redirected_to community_service_records_path
    assert_equal "Record not found", flash[:alert]
  end

  test "mentee can delete denied records via community service section" do
    @record.update!(approved: false)
    login_as(@mentee_user)
    assert_difference "CommunityServiceRecord.count", -1 do
      delete community_service_record_path(@record)
    end
    assert_redirected_to community_service_records_path
  end

  # Validation errors
  test "create with invalid params shows errors" do
    login_as(@mentor_user)
    post community_service_records_path, params: {
      community_service_record: {
        mentee_id: @mentee.id,
        event: "",
        event_date: nil,
        hours: 0
      }
    }
    assert_response :unprocessable_entity
  end
end
