# frozen_string_literal: true

module Mutations
  module Users
    class CreateUser < AuthenticatedMutation
      description "Create a new user (superuser only)"

      argument :input, Types::CreateUserInput, required: true

      field :user, Types::UserType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        unless superuser?
          return { user: nil, errors: ["You don't have permission to create users"] }
        end

        user = User.new(input.to_h)

        if user.save
          { user: user, errors: [] }
        else
          { user: nil, errors: user.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.staff.present?
      end
    end
  end
end
