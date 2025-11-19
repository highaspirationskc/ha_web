# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create Teams
blue_team = Team.find_or_create_by!(name: "Blue Team") do |team|
  team.color = :blue
end

green_team = Team.find_or_create_by!(name: "Green Team") do |team|
  team.color = :green
end

yellow_team = Team.find_or_create_by!(name: "Yellow Team") do |team|
  team.color = :yellow
end

red_team = Team.find_or_create_by!(name: "Red Team") do |team|
  team.color = :red
end

puts "Created 4 teams"

# Create test users for each role with team assignments
admin_user = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "Password1!"
  user.role = :admin
  user.active = true
  user.first_name = "Admin"
  user.last_name = "User"
end

staff_user = User.find_or_create_by!(email: "staff@example.com") do |user|
  user.password = "Password1!"
  user.role = :staff
  user.active = true
  user.first_name = "Staff"
  user.last_name = "User"
end

# Blue Team Users
blue_mentor = User.find_or_create_by!(email: "blue.mentor@example.com") do |user|
  user.password = "Password1!"
  user.role = :mentor
  user.active = true
  user.team = blue_team
  user.first_name = "Blue"
  user.last_name = "Mentor"
end

blue_mentee = User.find_or_create_by!(email: "blue.mentee@example.com") do |user|
  user.password = "Password1!"
  user.role = :mentee
  user.active = true
  user.team = blue_team
  user.first_name = "Blue"
  user.last_name = "Mentee"
end

blue_parent = User.find_or_create_by!(email: "blue.parent@example.com") do |user|
  user.password = "Password1!"
  user.role = :parent
  user.active = true
  user.team = blue_team
  user.first_name = "Blue"
  user.last_name = "Parent"
end

# Green Team Users
green_mentor = User.find_or_create_by!(email: "green.mentor@example.com") do |user|
  user.password = "Password1!"
  user.role = :mentor
  user.active = true
  user.team = green_team
  user.first_name = "Green"
  user.last_name = "Mentor"
end

green_mentee = User.find_or_create_by!(email: "green.mentee@example.com") do |user|
  user.password = "Password1!"
  user.role = :mentee
  user.active = true
  user.team = green_team
  user.first_name = "Green"
  user.last_name = "Mentee"
end

puts "Created test users with email pattern: role@example.com and password: Password1!"

# Create Olympic Seasons
winter_season = OlympicSeason.find_or_create_by!(name: "Winter") do |season|
  season.start_month = 12
  season.start_day = 1
  season.end_month = 2
  season.end_day = 28
end

spring_season = OlympicSeason.find_or_create_by!(name: "Spring") do |season|
  season.start_month = 3
  season.start_day = 1
  season.end_month = 5
  season.end_day = 31
end

summer_season = OlympicSeason.find_or_create_by!(name: "Summer") do |season|
  season.start_month = 6
  season.start_day = 1
  season.end_month = 8
  season.end_day = 31
end

fall_season = OlympicSeason.find_or_create_by!(name: "Fall") do |season|
  season.start_month = 9
  season.start_day = 1
  season.end_month = 11
  season.end_day = 30
end

puts "Created 4 olympic seasons"

# Create Event Types
workshop_type = EventType.find_or_create_by!(name: "Workshop") do |type|
  type.point_value = 10
  type.category = :org
end

mentoring_type = EventType.find_or_create_by!(name: "Mentoring Session") do |type|
  type.point_value = 5
  type.category = :user
end

competition_type = EventType.find_or_create_by!(name: "Competition") do |type|
  type.point_value = 20
  type.category = :org
end

community_service_type = EventType.find_or_create_by!(name: "Community Service") do |type|
  type.point_value = 15
  type.category = :org
end

study_session_type = EventType.find_or_create_by!(name: "Study Session") do |type|
  type.point_value = 5
  type.category = :user
end

puts "Created 5 event types"

# Create Events dynamically based on current date
today = Date.current
current_year = today.year

# Determine what year to use for each season based on current date
# Winter spans Dec-Feb, so if we're in Jan-Feb, use current year, otherwise use current year for Dec start
winter_year = today.month <= 2 ? current_year : current_year
spring_year = current_year
summer_year = current_year
fall_year = current_year

# Past season events (guaranteed to be in the past)
# Winter events (Dec-Feb of winter_year/winter_year+1)
Event.find_or_create_by!(name: "Winter Robotics Workshop") do |event|
  event.event_type = workshop_type
  event.description = "Learn robotics basics in this winter workshop"
  event.event_date = Date.new(winter_year, 1, 15)
  event.location = "Main Lab"
  event.created_by = admin_user
end

Event.find_or_create_by!(name: "Winter Study Session 1") do |event|
  event.event_type = study_session_type
  event.description = "Winter study session"
  event.event_date = Date.new(winter_year, 1, 20)
  event.location = "Library"
  event.created_by = blue_mentor
end

Event.find_or_create_by!(name: "Winter Study Session 2") do |event|
  event.event_type = study_session_type
  event.description = "Winter study session"
  event.event_date = Date.new(winter_year, 2, 10)
  event.location = "Library"
  event.created_by = green_mentor
end

# Spring events (Mar-May)
Event.find_or_create_by!(name: "Spring Workshop") do |event|
  event.event_type = workshop_type
  event.description = "Spring coding workshop"
  event.event_date = Date.new(spring_year, 3, 15)
  event.location = "Main Lab"
  event.created_by = staff_user
end

Event.find_or_create_by!(name: "Spring Coding Competition") do |event|
  event.event_type = competition_type
  event.description = "Annual spring coding competition"
  event.event_date = Date.new(spring_year, 4, 20)
  event.location = "Competition Hall"
  event.created_by = staff_user
end

Event.find_or_create_by!(name: "Spring Mentoring Session") do |event|
  event.event_type = mentoring_type
  event.description = "Spring mentoring session"
  event.event_date = Date.new(spring_year, 5, 10)
  event.location = "Meeting Room B"
  event.created_by = blue_mentor
end

# Summer events (Jun-Aug)
Event.find_or_create_by!(name: "Summer Workshop") do |event|
  event.event_type = workshop_type
  event.description = "Summer robotics workshop"
  event.event_date = Date.new(summer_year, 6, 15)
  event.location = "Main Lab"
  event.created_by = admin_user
end

Event.find_or_create_by!(name: "Summer Science Fair") do |event|
  event.event_type = competition_type
  event.description = "Summer science fair showcase"
  event.event_date = Date.new(summer_year, 7, 10)
  event.location = "Exhibition Center"
  event.created_by = admin_user
end

# Fall events (Sep-Nov)
Event.find_or_create_by!(name: "Fall Community Service") do |event|
  event.event_type = community_service_type
  event.description = "Fall community service day"
  event.event_date = Date.new(fall_year, 9, 15)
  event.location = "Community Center"
  event.created_by = staff_user
end

Event.find_or_create_by!(name: "Fall Workshop 1") do |event|
  event.event_type = workshop_type
  event.description = "Fall coding workshop"
  event.event_date = Date.new(fall_year, 10, 10)
  event.location = "Main Lab"
  event.created_by = staff_user
end

Event.find_or_create_by!(name: "Fall Workshop 2") do |event|
  event.event_type = workshop_type
  event.description = "Fall robotics workshop"
  event.event_date = Date.new(fall_year, 10, 25)
  event.location = "Main Lab"
  event.created_by = admin_user
end

# Future event (always in the future)
Event.find_or_create_by!(name: "Upcoming Mentoring Session") do |event|
  event.event_type = mentoring_type
  event.description = "Future mentoring session"
  event.event_date = today + 14.days
  event.location = "Meeting Room A"
  event.created_by = blue_mentor
end

puts "Created 12 events (current date: #{today})"

# Create Event Registrations and Logs dynamically
# Only create logs for events that have already happened (event_date < today)
winter_workshop = Event.find_by(name: "Winter Robotics Workshop")
winter_study_1 = Event.find_by(name: "Winter Study Session 1")
winter_study_2 = Event.find_by(name: "Winter Study Session 2")
spring_workshop = Event.find_by(name: "Spring Workshop")
spring_competition = Event.find_by(name: "Spring Coding Competition")
spring_mentoring = Event.find_by(name: "Spring Mentoring Session")
summer_workshop = Event.find_by(name: "Summer Workshop")
summer_fair = Event.find_by(name: "Summer Science Fair")
fall_service = Event.find_by(name: "Fall Community Service")
fall_workshop_1 = Event.find_by(name: "Fall Workshop 1")
fall_workshop_2 = Event.find_by(name: "Fall Workshop 2")
upcoming_mentoring = Event.find_by(name: "Upcoming Mentoring Session")

registration_count = 0
event_log_count = 0
blue_mentee_points = 0
green_mentee_points = 0

# Helper method to create registration and log if event is in the past
def create_event_participation(event, user, today, reg_days_before: 5)
  return nil unless event

  # Create registration
  reg = EventRegistration.find_or_create_by!(event: event, user: user) do |registration|
    registration.registration_date = event.event_date - reg_days_before.days
  end

  # Only create event log if event has already happened
  if event.event_date < today
    log = EventLog.find_or_create_by!(event: event, user: user) do |event_log|
      event_log.participated_at = event.event_date
      event_log.points_awarded = event.event_type.point_value
    end
    { registration: reg, log: log, points: event.event_type.point_value }
  else
    { registration: reg, log: nil, points: 0 }
  end
end

# Winter season participation
if winter_workshop
  result = create_event_participation(winter_workshop, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(winter_workshop, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

if winter_study_1
  result = create_event_participation(winter_study_1, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end
end

if winter_study_2
  result = create_event_participation(winter_study_2, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

# Spring season participation
if spring_workshop
  result = create_event_participation(spring_workshop, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(spring_workshop, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

if spring_competition
  result = create_event_participation(spring_competition, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(spring_competition, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

if spring_mentoring
  result = create_event_participation(spring_mentoring, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

# Summer season participation
if summer_workshop
  result = create_event_participation(summer_workshop, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(summer_workshop, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

if summer_fair
  result = create_event_participation(summer_fair, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(summer_fair, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

# Fall season participation (current season - only log if event has passed)
if fall_service
  result = create_event_participation(fall_service, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(fall_service, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

if fall_workshop_1
  result = create_event_participation(fall_workshop_1, blue_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    blue_mentee_points += result[:points]
  end

  result = create_event_participation(fall_workshop_1, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

if fall_workshop_2
  # Blue mentee registered but didn't attend
  EventRegistration.find_or_create_by!(event: fall_workshop_2, user: blue_mentee) do |reg|
    reg.registration_date = fall_workshop_2.event_date - 5.days
  end
  registration_count += 1

  result = create_event_participation(fall_workshop_2, green_mentee, today)
  registration_count += 1
  if result[:log]
    event_log_count += 1
    green_mentee_points += result[:points]
  end
end

# Future event - register but no logs yet
if upcoming_mentoring
  EventRegistration.find_or_create_by!(event: upcoming_mentoring, user: blue_mentee) do |reg|
    reg.registration_date = today
  end
  registration_count += 1

  EventRegistration.find_or_create_by!(event: upcoming_mentoring, user: green_mentee) do |reg|
    reg.registration_date = today
  end
  registration_count += 1
end

puts "Created #{registration_count} event registrations"
puts "Created #{event_log_count} event logs (only for past events)"
puts "Blue Team Mentee (#{blue_mentee.email}) total points: #{blue_mentee_points}"
puts "Green Team Mentee (#{green_mentee.email}) total points: #{green_mentee_points}"

# Create User Relationships
UserRelationship.find_or_create_by!(user: blue_mentee, related_user: blue_mentor) do |rel|
  rel.relationship_type = :mentor
end

UserRelationship.find_or_create_by!(user: blue_mentee, related_user: blue_parent) do |rel|
  rel.relationship_type = :parent
end

UserRelationship.find_or_create_by!(user: green_mentee, related_user: green_mentor) do |rel|
  rel.relationship_type = :mentor
end

puts "Created 3 user relationships"

puts "Seeding completed!"
