# frozen_string_literal: true

module Mutations
  class Register < BaseMutation
    description "Register a new user account"

    argument :input, Types::RegisterInput, required: true

    field :success, Boolean, null: false
    field :message, String, null: false
    field :errors, [String], null: true

    def resolve(input:)
      user = User.new(
        email: input[:email],
        password: input[:password],
        active: false
      )

      if user.save
        user.send_confirmation_email
        {
          success: true,
          message: "Registration successful! Please check your email to confirm your account.",
          errors: nil
        }
      else
        {
          success: false,
          message: "Registration failed",
          errors: user.errors.full_messages
        }
      end
    end
  end
end
