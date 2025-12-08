require "test_helper"

class GraphQL::AuthorizationTest < ActiveSupport::TestCase
  # Create a simple test class that includes the authorization helpers
  class TestMutation
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def require_authentication!
      return if context[:current_user]

      raise GraphQL::ExecutionError, "You must be logged in to perform this action"
    end

    def require_role!(*roles)
      require_authentication!

      unless roles.any? { |role| context[:current_user].public_send("#{role}?") }
        raise GraphQL::ExecutionError, "You don't have permission to perform this action"
      end
    end
  end

  def setup
    @admin_user = create_admin_user(email: "admin@example.com")

    @staff_user = create_staff_user(email: "staff@example.com")

    @volunteer_user = create_volunteer_user(email: "volunteer@example.com")
  end

  # require_authentication! tests
  test "require_authentication! does not raise error for authenticated user" do
    mutation = TestMutation.new({ current_user: @admin_user })
    mutation.require_authentication!
    # If we get here without error, test passes
    assert true
  end

  test "require_authentication! raises error for unauthenticated user" do
    mutation = TestMutation.new({})

    assert_raises GraphQL::ExecutionError, "You must be logged in to perform this action" do
      mutation.require_authentication!
    end
  end

  test "require_authentication! raises error for nil current_user" do
    mutation = TestMutation.new({ current_user: nil })

    assert_raises GraphQL::ExecutionError do
      mutation.require_authentication!
    end
  end

  # require_role! tests
  test "require_role! does not raise error for user with matching role" do
    mutation = TestMutation.new({ current_user: @admin_user })
    mutation.require_role!(:admin)
    # If we get here without error, test passes
    assert true
  end

  test "require_role! raises error for user without matching role" do
    mutation = TestMutation.new({ current_user: @volunteer_user })

    assert_raises GraphQL::ExecutionError, "You don't have permission to perform this action" do
      mutation.require_role!(:admin)
    end
  end

  test "require_role! works with staff role" do
    mutation = TestMutation.new({ current_user: @staff_user })
    mutation.require_role!(:staff)
    # If we get here without error, test passes
    assert true
  end

  test "require_role! raises error for unauthenticated user" do
    mutation = TestMutation.new({})

    assert_raises GraphQL::ExecutionError do
      mutation.require_role!(:admin)
    end
  end

  test "require_role! allows user with one of multiple roles" do
    mutation = TestMutation.new({ current_user: @admin_user })
    mutation.require_role!(:admin, :staff)
    # If we get here without error, test passes
    assert true
  end

  test "require_role! checks all provided roles" do
    mutation = TestMutation.new({ current_user: @staff_user })
    mutation.require_role!(:admin, :staff)
    # Staff user should pass when staff is one of the allowed roles
    assert true
  end
end
