# frozen_string_literal: true

module Mutations
  class Register < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true

    field :success, Boolean, null: false
    field :message, String, null: false
    field :errors, [String], null: true

    def resolve(email:, password:)
      user = User.new(
        email: email,
        password: password,
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
