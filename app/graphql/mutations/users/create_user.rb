# frozen_string_literal: true

module Mutations
  module Users
    class CreateUser < AuthenticatedMutation
      description "Create a new user with a role (staff only)"

      argument :input, Types::CreateUserInput, required: true

      field :user, Types::UserType, null: true
      field :errors, [String], null: false

      VALID_ROLES = %w[staff mentor mentee guardian volunteer].freeze

      def resolve(input:)
        unless superuser?
          return { user: nil, errors: ["You don't have permission to create users"] }
        end

        role = input[:role].to_s.downcase
        unless VALID_ROLES.include?(role)
          return { user: nil, errors: ["Invalid role. Must be one of: #{VALID_ROLES.join(', ')}"] }
        end

        ActiveRecord::Base.transaction do
          user = build_user(input)
          user.save!
          create_role_profile!(user, role, input)
          user.send_confirmation_email if @generated_password
          { user: user, errors: [] }
        end
      rescue ActiveRecord::RecordInvalid => e
        { user: nil, errors: e.record.errors.full_messages }
      end

      private

      def superuser?
        current_user.staff.present?
      end

      def build_user(input)
        user_attrs = input.to_h.slice(:email, :password, :first_name, :last_name)
        user = User.new(user_attrs)

        @generated_password = user.password.blank?
        if @generated_password
          user.password = generate_temporary_password
          user.active = false  # Must confirm account
        else
          user.active = true   # Password set, active immediately
        end

        user
      end

      def create_role_profile!(user, role, input)
        case role
        when "staff"
          permission_level = (input[:permission_level] || "standard").to_s.downcase
          Staff.create!(user: user, permission_level: permission_level)
        when "mentor"
          Mentor.create!(user: user)
        when "mentee"
          Mentee.create!(
            user: user,
            team_id: input[:team_id].presence,
            mentor_id: input[:mentor_id].presence
          )
        when "guardian"
          Guardian.create!(user: user)
        when "volunteer"
          Volunteer.create!(user: user)
        end
      end

      def generate_temporary_password
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + %w[! @ # $ % ^ & *]
        password = ""
        password += ("A".."Z").to_a.sample
        password += ("0".."9").to_a.sample
        password += %w[! @ # $ % ^ & *].sample
        password += Array.new(13) { chars.sample }.join
        password.chars.shuffle.join
      end
    end
  end
end
