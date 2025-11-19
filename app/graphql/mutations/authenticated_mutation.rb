# frozen_string_literal: true

module Mutations
  class AuthenticatedMutation < BaseMutation
    def ready?(**args)
      if context[:current_user].nil?
        raise GraphQL::ExecutionError, "Authentication required"
      end

      super
    end

    def current_user
      context[:current_user]
    end
  end
end
