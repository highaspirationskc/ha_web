# frozen_string_literal: true

module Mutations
  class Logout < BaseMutation
    description "Log out the current user"

    field :success, Boolean, null: false
    field :message, String, null: false

    def resolve
      current_user = context[:current_user]

      unless current_user
        return {
          success: false,
          message: "Not authenticated"
        }
      end

      # Extract the token from the Authorization header
      token = context[:controller].request.headers["Authorization"]&.sub(/^Bearer /, "")

      if token.present?
        hashed_token = Digest::SHA256.hexdigest(token)
        token_record = Token.find_by(token_hash: hashed_token)
        token_record&.destroy
      end

      {
        success: true,
        message: "Successfully logged out"
      }
    end
  end
end
