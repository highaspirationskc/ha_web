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

# Create parents (no team assignment)
blue_parent = User.find_or_create_by!(email: "blue.parent@example.com") do |user|
  user.password = "Password1!"
  user.role = :parent
  user.active = true
  user.first_name = "Blue"
  user.last_name = "Parent"
end

green_parent = User.find_or_create_by!(email: "green.parent@example.com") do |user|
  user.password = "Password1!"
  user.role = :parent
  user.active = true
  user.first_name = "Green"
  user.last_name = "Parent"
end

# Create mentors for each team (2-3 per team)
teams_data = [
  { team: blue_team, color: "Blue" },
  { team: green_team, color: "Green" },
  { team: yellow_team, color: "Yellow" },
  { team: red_team, color: "Red" }
]

all_mentors = []
all_mentees = []

teams_data.each do |team_data|
  team = team_data[:team]
  color = team_data[:color]

  # Create 2 mentors per team
  2.times do |i|
    mentor = User.find_or_create_by!(email: "#{color.downcase}.mentor#{i + 1}@example.com") do |user|
      user.password = "Password1!"
      user.role = :mentor
      user.active = true
      user.team = team
      user.first_name = "#{color}"
      user.last_name = "Mentor #{i + 1}"
    end
    all_mentors << mentor
  end

  # Create 7 mentees per team
  7.times do |i|
    mentee = User.find_or_create_by!(email: "#{color.downcase}.mentee#{i + 1}@example.com") do |user|
      user.password = "Password1!"
      user.role = :mentee
      user.active = true
      user.team = team
      user.first_name = "#{color}"
      user.last_name = "Mentee #{i + 1}"
    end
    all_mentees << mentee
  end
end

# Keep references to first blue and green mentees for backward compatibility with event logs
blue_mentee = User.find_by(email: "blue.mentee1@example.com")
green_mentee = User.find_by(email: "green.mentee1@example.com")
blue_mentor = User.find_by(email: "blue.mentor1@example.com")
green_mentor = User.find_by(email: "green.mentor1@example.com")

puts "Created test users: 2 parents, #{all_mentors.count} mentors, #{all_mentees.count} mentees (password: Password1!)"

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
  type.point_value = 1
  type.category = :org
end

mentoring_type = EventType.find_or_create_by!(name: "Mentoring Session") do |type|
  type.point_value = 1
  type.category = :user
end

competition_type = EventType.find_or_create_by!(name: "Competition") do |type|
  type.point_value = 1
  type.category = :org
end

community_service_type = EventType.find_or_create_by!(name: "Community Service") do |type|
  type.point_value = 1
  type.category = :org
end

study_session_type = EventType.find_or_create_by!(name: "Study Session") do |type|
  type.point_value = 1
  type.category = :user
end

# Update existing event types to have point_value of 1
EventType.update_all(point_value: 1)

puts "Created 5 event types (all with point_value: 1)"

# Create Events dynamically - one event every Saturday for each season
today = Date.current
current_year = today.year

# Helper to find all Saturdays in a date range
def saturdays_in_range(start_date, end_date)
  saturdays = []
  current = start_date
  # Find first Saturday
  current += (6 - current.wday) % 7
  while current <= end_date
    saturdays << current
    current += 7.days
  end
  saturdays
end

# Event types array for rotation
event_types_array = [workshop_type, mentoring_type, competition_type, community_service_type, study_session_type]
locations = ["Main Lab", "Library", "Community Center", "Meeting Room A", "Meeting Room B", "Competition Hall"]
event_counter = 0

seasons = [
  { name: "Winter", season: winter_season, start_month: 12, end_month: 2 },
  { name: "Spring", season: spring_season, start_month: 3, end_month: 5 },
  { name: "Summer", season: summer_season, start_month: 6, end_month: 8 },
  { name: "Fall", season: fall_season, start_month: 9, end_month: 11 }
]

all_events = []

seasons.each do |season_data|
  # Calculate season date range
  if season_data[:start_month] > season_data[:end_month]
    # Season spans years (Winter: Dec-Feb)
    if today.month <= season_data[:end_month]
      # We're in the end of the season (Jan-Feb)
      start_date = Date.new(current_year - 1, season_data[:start_month], 1)
      end_date = Date.new(current_year, season_data[:end_month], -1)
    else
      # We're before or in the start of the season
      start_date = Date.new(current_year, season_data[:start_month], 1)
      end_date = Date.new(current_year + 1, season_data[:end_month], -1)
    end
  else
    # Season within same year
    start_date = Date.new(current_year, season_data[:start_month], 1)
    end_date = Date.new(current_year, season_data[:end_month], -1)
  end

  # Find all Saturdays in this season
  saturdays = saturdays_in_range(start_date, end_date)

  # Create an event for each Saturday
  saturdays.each_with_index do |saturday, index|
    event_type = event_types_array[event_counter % event_types_array.length]
    location = locations[event_counter % locations.length]

    event = Event.find_or_create_by!(
      event_date: saturday,
      event_type: event_type
    ) do |e|
      e.name = "#{season_data[:name]} #{event_type.name} - Week #{index + 1}"
      e.description = "#{season_data[:name]} season event - #{event_type.name}"
      e.location = location
      e.created_by = [admin_user, staff_user, all_mentors.sample].compact.sample
    end

    all_events << event
    event_counter += 1
  end
end

puts "Created #{all_events.length} events (one per Saturday for each season, current date: #{today})"

# Separate events into past and future, and by season
past_events = all_events.select { |event| event.event_date < today }
future_events = all_events.select { |event| event.event_date >= today }

# Get current season events (past)
current_season_name = @current_season&.name || OlympicSeason.current_season&.name
current_season_past_events = past_events.select do |event|
  event.name.start_with?(current_season_name) if current_season_name
end

# Get other season past events
other_season_past_events = past_events.reject do |event|
  event.name.start_with?(current_season_name) if current_season_name
end

registration_count = 0
event_log_count = 0

# Helper method to create registration and arrival log if event is in the past
def create_event_participation(event, user, today, reg_days_before: 5)
  return nil unless event

  # Create registration log
  reg_log = EventLog.find_or_create_by!(event: event, user: user, log_type: :registered) do |log|
    log.logged_at = event.event_date - reg_days_before.days
  end

  # Only create arrival log if event has already happened
  if event.event_date < today
    arrival_log = EventLog.find_or_create_by!(event: event, user: user, log_type: :arrived) do |log|
      log.logged_at = event.event_date
    end
    { registration: reg_log, arrival: arrival_log, points: event.event_type.point_value }
  else
    { registration: reg_log, arrival: nil, points: 0 }
  end
end

# Randomize event participation for all mentees
all_mentees.each do |mentee|
  # Each mentee participates in 1 to ALL current season events (allowing perfect participation)
  if current_season_past_events.any?
    num_current_events = rand(1..current_season_past_events.length)
    selected_current_events = current_season_past_events.sample(num_current_events)

    selected_current_events.each do |event|
      result = create_event_participation(event, mentee, today, reg_days_before: rand(3..10))
      registration_count += 1
      event_log_count += 1 if result[:arrival]
    end
  end

  # 50% chance to also participate in 1-5 events from other seasons (for variety)
  if rand < 0.5 && other_season_past_events.any?
    num_other_events = rand(1..[5, other_season_past_events.length].min)
    selected_other_events = other_season_past_events.sample(num_other_events)

    selected_other_events.each do |event|
      result = create_event_participation(event, mentee, today, reg_days_before: rand(3..10))
      registration_count += 1
      event_log_count += 1 if result[:arrival]
    end
  end

  # Register for a few future events (10% chance per future event)
  future_events.sample([future_events.length, 2].min).each do |event|
    next unless rand < 0.1

    EventLog.find_or_create_by!(event: event, user: mentee, log_type: :registered) do |log|
      log.logged_at = [today, event.event_date - 7.days].max
    end
    registration_count += 1
  end
end

puts "Created #{registration_count} event registrations"
puts "Created #{event_log_count} event logs (only for past events)"

# Create User Relationships (only mentor relationships, since parents are not on teams)
UserRelationship.find_or_create_by!(user: blue_mentee, related_user: blue_mentor) do |rel|
  rel.relationship_type = :mentor
end

UserRelationship.find_or_create_by!(user: green_mentee, related_user: green_mentor) do |rel|
  rel.relationship_type = :mentor
end

puts "Created 2 user relationships"

puts "Seeding completed!"
