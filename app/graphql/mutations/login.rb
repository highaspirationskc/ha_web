# frozen_string_literal: true

module Mutations
  class Login < BaseMutation
    description "Authenticate a user and return a token"

    argument :input, Types::LoginInput, required: true

    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [String], null: true

    def resolve(input:)
      user = User.find_by(email: input[:email].downcase.strip)

      unless user&.authenticate(input[:password])
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

      token = AuthService.generate_token(user, device_name: input[:device_name])

      {
        token: token,
        user: user,
        errors: nil
      }
    end
  end
end
