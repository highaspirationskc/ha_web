require "test_helper"

class SaturdayScoopsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      email: "admin_scoops@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @admin, permission_level: :admin)
    @admin.activate!

    @staff = User.create!(
      email: "staff_scoops@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @staff, permission_level: :standard)
    @staff.activate!

    @mentor = User.create!(
      email: "mentor_scoops@example.com",
      password: "Password123!"
    )
    Mentor.create!(user: @mentor)
    @mentor.activate!

    @scoop = SaturdayScoop.create!(
      title: "Test Scoop",
      author: "Test Author",
      description: "Test description",
      created_by: @admin
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Authentication tests
  test "index requires authentication" do
    get saturday_scoops_url
    assert_redirected_to root_path
  end

  test "show requires authentication" do
    get saturday_scoop_url(@scoop)
    assert_redirected_to root_path
  end

  test "new requires authentication" do
    get new_saturday_scoop_url
    assert_redirected_to root_path
  end

  test "create requires authentication" do
    post saturday_scoops_url, params: { saturday_scoop: { title: "New Scoop", author: "Author" } }
    assert_redirected_to root_path
  end

  test "edit requires authentication" do
    get edit_saturday_scoop_url(@scoop)
    assert_redirected_to root_path
  end

  test "update requires authentication" do
    patch saturday_scoop_url(@scoop), params: { saturday_scoop: { title: "Updated" } }
    assert_redirected_to root_path
  end

  test "destroy requires authentication" do
    delete saturday_scoop_url(@scoop)
    assert_redirected_to root_path
  end

  # Authorization tests - admin
  test "admin can view index" do
    login_as @admin
    get saturday_scoops_url
    assert_response :success
  end

  test "admin can view show" do
    login_as @admin
    get saturday_scoop_url(@scoop)
    assert_response :success
  end

  test "admin can view new" do
    login_as @admin
    get new_saturday_scoop_url
    assert_response :success
  end

  test "admin can create scoop" do
    login_as @admin

    assert_difference("SaturdayScoop.count", 1) do
      post saturday_scoops_url, params: {
        saturday_scoop: {
          title: "New Scoop",
          author: "New Author",
          description: "New description"
        }
      }
    end

    scoop = SaturdayScoop.last
    assert_redirected_to saturday_scoop_url(scoop)
    assert_equal @admin, scoop.created_by
  end

  test "admin can view edit" do
    login_as @admin
    get edit_saturday_scoop_url(@scoop)
    assert_response :success
  end

  test "admin can update scoop" do
    login_as @admin

    patch saturday_scoop_url(@scoop), params: {
      saturday_scoop: { title: "Updated Title" }
    }

    assert_redirected_to saturday_scoop_url(@scoop)
    @scoop.reload
    assert_equal "Updated Title", @scoop.title
  end

  test "admin can delete scoop" do
    login_as @admin

    assert_difference("SaturdayScoop.count", -1) do
      delete saturday_scoop_url(@scoop)
    end

    assert_redirected_to saturday_scoops_url
  end

  test "admin can publish scoop" do
    login_as @admin
    @scoop.update!(published: false)

    post publish_saturday_scoop_url(@scoop)

    assert_redirected_to saturday_scoop_url(@scoop)
    @scoop.reload
    assert @scoop.published?
  end

  test "admin can unpublish scoop" do
    login_as @admin
    @scoop.update!(published: true)

    post unpublish_saturday_scoop_url(@scoop)

    assert_redirected_to saturday_scoop_url(@scoop)
    @scoop.reload
    assert_not @scoop.published?
  end

  # Authorization tests - staff
  test "staff can view index" do
    login_as @staff
    get saturday_scoops_url
    assert_response :success
  end

  test "staff can view show" do
    login_as @staff
    get saturday_scoop_url(@scoop)
    assert_response :success
  end

  test "staff can create scoop" do
    login_as @staff

    assert_difference("SaturdayScoop.count", 1) do
      post saturday_scoops_url, params: {
        saturday_scoop: {
          title: "Staff Scoop",
          author: "Staff Author",
          description: "Staff description"
        }
      }
    end

    scoop = SaturdayScoop.last
    assert_equal @staff, scoop.created_by
  end

  test "staff can update scoop" do
    login_as @staff

    patch saturday_scoop_url(@scoop), params: {
      saturday_scoop: { title: "Staff Updated" }
    }

    assert_redirected_to saturday_scoop_url(@scoop)
  end

  test "staff can delete scoop" do
    login_as @staff

    assert_difference("SaturdayScoop.count", -1) do
      delete saturday_scoop_url(@scoop)
    end
  end

  test "staff can publish scoop" do
    login_as @staff
    @scoop.update!(published: false)

    post publish_saturday_scoop_url(@scoop)

    @scoop.reload
    assert @scoop.published?
  end

  # Authorization tests - mentor (should be denied)
  test "mentor cannot access saturday scoops" do
    login_as @mentor
    get saturday_scoops_url
    assert_redirected_to dashboard_path
  end

  test "mentor cannot create scoop" do
    login_as @mentor

    assert_no_difference("SaturdayScoop.count") do
      post saturday_scoops_url, params: {
        saturday_scoop: {
          title: "Mentor Scoop",
          author: "Mentor Author"
        }
      }
    end
  end

  # Validation error handling
  test "create with invalid data renders new form" do
    login_as @admin

    assert_no_difference("SaturdayScoop.count") do
      post saturday_scoops_url, params: {
        saturday_scoop: { title: "", author: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update with invalid data renders edit form" do
    login_as @admin

    patch saturday_scoop_url(@scoop), params: {
      saturday_scoop: { title: "" }
    }

    assert_response :unprocessable_entity
  end
end
