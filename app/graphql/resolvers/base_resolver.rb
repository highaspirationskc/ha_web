# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    # Helper method to require authentication
    def require_authentication!
      return if context[:current_user]

      raise GraphQL::ExecutionError, "You must be logged in to perform this action"
    end

    # Helper method to check for specific roles
    def require_role!(*roles)
      require_authentication!

      unless roles.any? { |role| context[:current_user].public_send("#{role}?") }
        raise GraphQL::ExecutionError, "You don't have permission to perform this action"
      end
    end
  end
end
