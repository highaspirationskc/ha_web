require "test_helper"

class SeasDomainsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "seas_domains_admin@example.com")
    @staff = create_staff_user(email: "seas_domains_staff@example.com")
    @domain = SeasDomain.create!(name: "Test Domain", position: 1)

    login_as(@admin)
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # ============================================
  # index
  # ============================================

  test "index lists all domains for admin" do
    get seas_domains_path
    assert_response :success
    assert_select "td", text: "Test Domain"
  end

  test "index lists all domains for staff" do
    reset!
    login_as(@staff)
    get seas_domains_path
    assert_response :success
  end

  test "index redirects unauthorized users" do
    mentee_user = create_mentee_user(email: "seas_domains_mentee@example.com")
    reset!
    login_as(mentee_user)
    get seas_domains_path
    assert_redirected_to dashboard_path
  end

  # ============================================
  # show
  # ============================================

  test "show displays domain with questions" do
    SeasQuestion.create!(seas_domain: @domain, text: "Test Q", position: 1)
    get seas_domain_path(@domain)
    assert_response :success
    assert_select "td", text: "Test Q"
  end

  # ============================================
  # new / create
  # ============================================

  test "new renders form" do
    get new_seas_domain_path
    assert_response :success
  end

  test "create adds a new domain" do
    assert_difference "SeasDomain.count", 1 do
      post seas_domains_path, params: { seas_domain: { name: "New Domain", position: 5 } }
    end
    assert_redirected_to seas_domain_path(SeasDomain.last)
  end

  test "create renders new on validation error" do
    post seas_domains_path, params: { seas_domain: { name: "", position: 5 } }
    assert_response :unprocessable_entity
  end

  # ============================================
  # edit / update
  # ============================================

  test "edit renders form" do
    get edit_seas_domain_path(@domain)
    assert_response :success
  end

  test "update modifies domain" do
    patch seas_domain_path(@domain), params: { seas_domain: { name: "Updated Name" } }
    assert_redirected_to seas_domain_path(@domain)
    @domain.reload
    assert_equal "Updated Name", @domain.name
  end

  test "update renders edit on validation error" do
    patch seas_domain_path(@domain), params: { seas_domain: { name: "" } }
    assert_response :unprocessable_entity
  end

  # ============================================
  # destroy
  # ============================================

  test "destroy removes domain" do
    assert_difference "SeasDomain.count", -1 do
      delete seas_domain_path(@domain)
    end
    assert_redirected_to seas_domains_path
  end

  test "destroy cascades to questions" do
    SeasQuestion.create!(seas_domain: @domain, text: "Test Q", position: 1)
    assert_difference "SeasQuestion.count", -1 do
      delete seas_domain_path(@domain)
    end
  end
end
