ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Helper methods for creating users with role profiles
    def create_user(email: "admin@example.com", password: "Password123!", active: true)
      user = User.create!(email: email, password: password)
      Staff.create!(user: user, permission_level: :admin)
      user.activate! if active
      user
    end

    def create_staff_user(email: "staff@example.com", password: "Password123!", active: true)
      user = User.create!(email: email, password: password)
      Staff.create!(user: user, permission_level: :standard)
      user.activate! if active
      user
    end

    def create_mentor_user(email: "mentor@example.com", password: "Password123!", active: true)
      user = User.create!(email: email, password: password)
      Mentor.create!(user: user)
      user.activate! if active
      user
    end

    def create_mentee_user(email: "mentee@example.com", password: "Password123!", team: nil, mentor: nil, active: true)
      user = User.create!(email: email, password: password)
      Mentee.create!(user: user, team: team, mentor: mentor)
      user.activate! if active
      user
    end

    def create_guardian_user(email: "guardian@example.com", password: "Password123!", active: true)
      user = User.create!(email: email, password: password)
      Guardian.create!(user: user)
      user.activate! if active
      user
    end

    def create_volunteer_user(email: "volunteer@example.com", password: "Password123!", active: true)
      user = User.create!(email: email, password: password)
      Volunteer.create!(user: user)
      user.activate! if active
      user
    end
  end
end
