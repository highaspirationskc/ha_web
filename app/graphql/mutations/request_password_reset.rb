# frozen_string_literal: true

module Mutations
  class RequestPasswordReset < BaseMutation
    description "Request a password reset email"

    argument :email, String, required: true

    field :success, Boolean, null: false
    field :message, String, null: false

    def resolve(email:)
      user = User.find_by(email: email.downcase.strip)

      if user&.active?
        user.request_password_reset!
      end

      {
        success: true,
        message: "If an account exists with this email, a password reset link has been sent."
      }
    end
  end
end
