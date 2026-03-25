require "test_helper"

class IncentivesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "incentives_admin@example.com")
    @staff = create_staff_user(email: "incentives_staff@example.com")
    @mentor = create_mentor_user(email: "incentives_mentor@example.com")
    @incentive = Incentive.create!(
      name: "Jack Stack Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      active: true,
      created_by: @admin
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Authentication
  test "should redirect to login when not authenticated" do
    get incentives_path
    assert_redirected_to root_path
  end

  # Authorization - mentors should not access
  test "should redirect mentor to dashboard" do
    login_as(@mentor)
    get incentives_path
    assert_redirected_to dashboard_path
  end

  # Index
  test "admin can view incentives index" do
    login_as(@admin)
    get incentives_path
    assert_response :success
  end

  test "staff can view incentives index" do
    login_as(@staff)
    get incentives_path
    assert_response :success
  end

  test "index displays incentive name" do
    login_as(@admin)
    get incentives_path
    assert_select "td", /Jack Stack Gift Card/
  end

  test "index filters by team type" do
    team_incentive = Incentive.create!(name: "Team Dinner", point_cost: 5000, incentive_type: "team", created_by: @admin)

    login_as(@admin)
    get incentives_path(filter: "team")
    assert_response :success
  end

  test "index filters by individual type" do
    login_as(@admin)
    get incentives_path(filter: "individual")
    assert_response :success
  end

  # New
  test "admin can view new incentive form" do
    login_as(@admin)
    get new_incentive_path
    assert_response :success
  end

  test "staff can view new incentive form" do
    login_as(@staff)
    get new_incentive_path
    assert_response :success
  end

  # Create
  test "admin can create incentive" do
    login_as(@admin)
    assert_difference "Incentive.count", 1 do
      post incentives_path, params: {
        incentive: {
          name: "Shop With a Pro",
          description: "Shopping experience",
          point_cost: 75,
          incentive_type: "individual",
          active: true
        }
      }
    end
    assert_redirected_to incentives_path
    follow_redirect!
    assert_select ".bg-green-50", /successfully created/
  end

  test "create with invalid params renders new" do
    login_as(@admin)
    assert_no_difference "Incentive.count" do
      post incentives_path, params: {
        incentive: {
          name: "",
          point_cost: nil,
          incentive_type: "individual"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create sets created_by to current user" do
    login_as(@staff)
    post incentives_path, params: {
      incentive: {
        name: "New Incentive",
        point_cost: 50,
        incentive_type: "team",
        active: true
      }
    }
    assert_equal @staff.id, Incentive.last.created_by_id
  end

  # Edit
  test "admin can view edit incentive form" do
    login_as(@admin)
    get edit_incentive_path(@incentive)
    assert_response :success
  end

  # Update
  test "admin can update incentive" do
    login_as(@admin)
    patch incentive_path(@incentive), params: {
      incentive: { name: "Updated Gift Card", point_cost: 50 }
    }
    assert_redirected_to incentives_path
    @incentive.reload
    assert_equal "Updated Gift Card", @incentive.name
    assert_equal 50, @incentive.point_cost
  end

  test "update with invalid params renders edit" do
    login_as(@admin)
    patch incentive_path(@incentive), params: {
      incentive: { name: "", point_cost: 0 }
    }
    assert_response :unprocessable_entity
  end

  # Destroy
  test "admin can delete incentive" do
    login_as(@admin)
    assert_difference "Incentive.count", -1 do
      delete incentive_path(@incentive)
    end
    assert_redirected_to incentives_path
  end

  # Active/Inactive display
  test "can toggle incentive active status" do
    login_as(@admin)
    patch incentive_path(@incentive), params: {
      incentive: { active: false }
    }
    @incentive.reload
    assert_not @incentive.active?
  end
end
