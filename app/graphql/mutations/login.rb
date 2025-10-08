# frozen_string_literal: true

module Mutations
  class Login < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true
    argument :device_name, String, required: false

    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [String], null: true

    def resolve(email:, password:, device_name: nil)
      user = User.find_by(email: email.downcase.strip)

      unless user&.authenticate(password)
        return {
          token: nil,
          user: nil,
          errors: ["Invalid email or password"]
        }
      end

      unless user.active?
        return {
          token: nil,
          user: nil,
          errors: ["Please confirm your email address before logging in"]
        }
      end

      token = AuthService.generate_token(user, device_name: device_name)

      {
        token: token,
        user: user,
        errors: nil
      }
    end
  end
end
