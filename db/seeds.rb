# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create test users for each role
User.find_or_create_by!(email: "test@example.com") do |user|
  user.password = "Password1!"
  user.role = :admin
  user.active = true
end

User.find_or_create_by!(email: "staff@example.com") do |user|
  user.password = "Password1!"
  user.role = :staff
  user.active = true
end

User.find_or_create_by!(email: "volunteer@example.com") do |user|
  user.password = "Password1!"
  user.role = :volunteer
  user.active = true
end

User.find_or_create_by!(email: "mentor@example.com") do |user|
  user.password = "Password1!"
  user.role = :mentor
  user.active = true
end

User.find_or_create_by!(email: "mentee@example.com") do |user|
  user.password = "Password1!"
  user.role = :mentee
  user.active = true
end

User.find_or_create_by!(email: "parent@example.com") do |user|
  user.password = "Password1!"
  user.role = :parent
  user.active = true
end

puts "Created test users with email pattern: role@example.com and password: Password1!"
