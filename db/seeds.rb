# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create Teams
team_definitions = [
  { name: "Blue Team", color: "#3B82F6" },
  { name: "Green Team", color: "#22C55E" },
  { name: "Yellow Team", color: "#F59E0B" },
  { name: "Red Team", color: "#E11D48" },
  { name: "Orange Team", color: "#F97316" },
  { name: "Emerald Team", color: "#10B981" },
  { name: "Teal Team", color: "#14B8A6" },
  { name: "Cyan Team", color: "#06B6D4" },
  { name: "Sky Team", color: "#0EA5E9" },
  { name: "Indigo Team", color: "#6366F1" },
  { name: "Violet Team", color: "#8B5CF6" },
  { name: "Purple Team", color: "#A855F7" },
  { name: "Fuchsia Team", color: "#D946EF" },
  { name: "Pink Team", color: "#EC4899" },
  { name: "Rose Team", color: "#F43F5E" },
  { name: "Lime Team", color: "#84CC16" },
  { name: "Slate Team", color: "#64748B" },
  { name: "Navy Team", color: "#1E3A8A" },
  { name: "Forest Team", color: "#166534" },
  { name: "Amber Team", color: "#92400E" }
]

all_teams = team_definitions.map do |defn|
  Team.find_or_create_by!(name: defn[:name]) do |team|
    team.color = defn[:color]
  end
end

puts "Created #{all_teams.size} teams"

# Named references for backward compatibility
all_teams[0]
all_teams[1]
all_teams[2]
all_teams[3]

# Helper method to create user with role profile
def create_user_with_role(email:, first_name:, last_name:, password: "Password1!", active: true, &block)
  user = User.find_or_create_by!(email: email) do |u|
    u.password = password
    u.first_name = first_name
    u.last_name = last_name
  end
  user.update!(active: active) if active && !user.active?
  yield(user) if block_given?
  user
end

# Create admin user
admin_user = create_user_with_role(email: "admin@example.com", first_name: "Admin", last_name: "User") do |user|
  Staff.find_or_create_by!(user: user) { |s| s.permission_level = :admin }
end

# Create staff user
staff_user = create_user_with_role(email: "staff@example.com", first_name: "Staff", last_name: "User") do |user|
  Staff.find_or_create_by!(user: user) { |s| s.permission_level = :standard }
end

# Create guardians (no team assignment)
blue_guardian_user = create_user_with_role(email: "blue.parent@example.com", first_name: "Blue", last_name: "Parent") do |user|
  Guardian.find_or_create_by!(user: user)
end
blue_guardian = blue_guardian_user.guardian

green_guardian_user = create_user_with_role(email: "green.parent@example.com", first_name: "Green", last_name: "Parent") do |user|
  Guardian.find_or_create_by!(user: user)
end
green_guardian = green_guardian_user.guardian

puts "Created 2 guardians"

# Create mentors and mentees for each team
teams_data = all_teams.map do |team|
  { team: team, label: team.name.sub(" Team", "") }
end

all_mentors = []
all_mentees = []
all_mentee_users = []

teams_data.each do |team_data|
  team = team_data[:team]
  label = team_data[:label]
  prefix = label.downcase.gsub(/\s+/, "-")

  # Create 2 mentors per team
  2.times do |i|
    mentor_user = create_user_with_role(
      email: "#{prefix}.mentor#{i + 1}@example.com",
      first_name: label,
      last_name: "Mentor #{i + 1}"
    ) do |user|
      Mentor.find_or_create_by!(user: user)
    end
    all_mentors << mentor_user.mentor
  end

  # Create 7 mentees per team
  7.times do |i|
    mentee_user = create_user_with_role(
      email: "#{prefix}.mentee#{i + 1}@example.com",
      first_name: label,
      last_name: "Mentee #{i + 1}"
    ) do |user|
      mentee = Mentee.find_or_create_by!(user: user)
      mentee.update!(team: team) if mentee.team != team
    end
    all_mentees << mentee_user.mentee
    all_mentee_users << mentee_user
  end
end

# Keep references to first blue and green mentees for backward compatibility with event logs
blue_mentee_user = User.find_by(email: "blue.mentee1@example.com")
green_mentee_user = User.find_by(email: "green.mentee1@example.com")
User.find_by(email: "blue.mentor1@example.com")
User.find_by(email: "green.mentor1@example.com")

puts "Created test users: 2 guardians, #{all_mentors.count} mentors, #{all_mentees.count} mentees (password: Password1!)"

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

# Update existing event types to have reasonable point values
EventType.find_by(name: "Workshop")&.update!(point_value: 10)
EventType.find_by(name: "Mentoring Session")&.update!(point_value: 5)
EventType.find_by(name: "Competition")&.update!(point_value: 15)
EventType.find_by(name: "Community Service")&.update!(point_value: 20)
EventType.find_by(name: "Study Session")&.update!(point_value: 5)

puts "Updated 5 event types with point values: Workshop (10), Mentoring (5), Competition (15), Community Service (20), Study Session (5)"

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
      e.created_by = [admin_user, staff_user, all_mentors.sample&.user].compact.sample
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
    log.points_awarded = 0  # No points for registration
  end

  # Only create arrival log if event has already happened
  if event.event_date < today
    arrival_log = EventLog.find_or_create_by!(event: event, user: user, log_type: :arrived) do |log|
      log.logged_at = event.event_date
      log.points_awarded = event.event_type.point_value  # Award points based on event type
    end
    { registration: reg_log, arrival: arrival_log, points: event.event_type.point_value }
  else
    { registration: reg_log, arrival: nil, points: 0 }
  end
end

# Randomize event participation for all mentees
all_mentee_users.each do |mentee_user|
  # Each mentee participates in 1 to ALL current season events (allowing perfect participation)
  if current_season_past_events.any?
    num_current_events = rand(1..current_season_past_events.length)
    selected_current_events = current_season_past_events.sample(num_current_events)

    selected_current_events.each do |event|
      result = create_event_participation(event, mentee_user, today, reg_days_before: rand(3..10))
      registration_count += 1
      event_log_count += 1 if result[:arrival]
    end
  end

  # 50% chance to also participate in 1-5 events from other seasons (for variety)
  if rand < 0.5 && other_season_past_events.any?
    num_other_events = rand(1..[5, other_season_past_events.length].min)
    selected_other_events = other_season_past_events.sample(num_other_events)

    selected_other_events.each do |event|
      result = create_event_participation(event, mentee_user, today, reg_days_before: rand(3..10))
      registration_count += 1
      event_log_count += 1 if result[:arrival]
    end
  end

  # Register for a few future events (10% chance per future event)
  future_events.sample([future_events.length, 2].min).each do |event|
    next unless rand < 0.1

    EventLog.find_or_create_by!(event: event, user: mentee_user, log_type: :registered) do |log|
      log.logged_at = [today, event.event_date - 7.days].max
    end
    registration_count += 1
  end
end

puts "Created #{registration_count} event registrations"
puts "Created #{event_log_count} event logs (only for past events)"

# Create Family Members (guardian-mentee relationships)
if blue_mentee_user&.mentee && blue_guardian
  FamilyMember.find_or_create_by!(guardian: blue_guardian, mentee: blue_mentee_user.mentee) do |fm|
    fm.relationship_type = :parent
  end
end

if green_mentee_user&.mentee && green_guardian
  FamilyMember.find_or_create_by!(guardian: green_guardian, mentee: green_mentee_user.mentee) do |fm|
    fm.relationship_type = :parent
  end
end

puts "Created 2 family member relationships"

# Create SEAS Sections and Questions
seas_data = {
  "Social" => {
    position: 1,
    questions: [
      "Employment/job seeking activity",
      "Participation during sessions",
      "Respectful communication with mentors and leaders"
    ]
  },
  "Emotional" => {
    position: 2,
    questions: [
      "Managing emotions in difficult situations",
      "Expressing feelings in healthy ways",
      "Showing empathy toward others"
    ]
  },
  "Academic" => {
    position: 3,
    questions: [
      "Completing homework and assignments on time",
      "Setting and working toward academic goals",
      "Asking for help when needed"
    ]
  },
  "Spiritual" => {
    position: 4,
    questions: [
      "Reflecting on personal values and beliefs",
      "Making positive choices under pressure",
      "Being a positive influence on others"
    ]
  }
}

seas_data.each do |domain_name, data|
  section = SeasDomain.find_or_create_by!(name: domain_name) do |s|
    s.position = data[:position]
  end

  data[:questions].each_with_index do |text, index|
    SeasQuestion.find_or_create_by!(seas_domain: section, text: text) do |q|
      q.position = index + 1
    end
  end
end

puts "Created #{SeasDomain.count} SEAS domains with #{SeasQuestion.count} questions"

# Backfill enrollment_date on mentees from their user's created_at
Mentee.where(enrollment_date: nil).find_each do |mentee|
  mentee.update!(enrollment_date: mentee.user.created_at.to_date)
end

# Backfill points_awarded for existing event logs based on event type
EventLog.where(log_type: :arrived).find_each do |log|
  next unless log.event&.event_type
  correct_points = log.event.event_type.point_value
  log.update!(points_awarded: correct_points) if log.points_awarded != correct_points
end

puts "Backfilled points_awarded for #{EventLog.where(log_type: :arrived).count} arrival logs"

# Create Incentives for Redemption System
puts "Creating incentives..."

incentives_data = [
  { name: "Jack Stack Gift Card", description: "$25 BBQ gift card", point_cost: 25, incentive_type: "individual" },
  { name: "Movie Pass", description: "AMC movie ticket", point_cost: 15, incentive_type: "individual" },
  { name: "Pizza Voucher", description: "$20 Pizza Hut gift card", point_cost: 20, incentive_type: "individual" },
  { name: "Book Voucher", description: "$15 Barnes & Noble gift card", point_cost: 15, incentive_type: "individual" },
  { name: "Sports Equipment", description: "Basketball or soccer ball", point_cost: 30, incentive_type: "individual" },
  { name: "School Supplies Kit", description: "Backpack with supplies", point_cost: 35, incentive_type: "individual" },
  { name: "Gaming Card", description: "$20 GameStop gift card", point_cost: 20, incentive_type: "individual" },
  { name: "Music Subscription", description: "3-month Spotify subscription", point_cost: 25, incentive_type: "individual" },
  # Team incentives
  { name: "Team Pizza Party", description: "Pizza party for the entire team", point_cost: 100, incentive_type: "team" },
  { name: "Team Bowling", description: "Bowling outing for the team", point_cost: 80, incentive_type: "team" },
  { name: "Team Movie Day", description: "Private movie screening for the team", point_cost: 120, incentive_type: "team" },
  { name: "Team BBQ", description: "Team cookout at the park", point_cost: 150, incentive_type: "team" }
]

incentives = incentives_data.map do |data|
  Incentive.find_or_create_by!(name: data[:name]) do |i|
    i.description = data[:description]
    i.point_cost = data[:point_cost]
    i.incentive_type = data[:incentive_type]
    i.created_by = admin_user
  end
end

individual_count = incentives.count { |i| i.incentive_type == "individual" }
team_count = incentives.count { |i| i.incentive_type == "team" }
puts "Created #{incentives.length} incentives (#{individual_count} individual, #{team_count} team)"

# Create sample redemptions for testing
puts "Creating sample redemptions..."

# Pick a few mentees to have redemptions
sample_mentees = all_mentees.sample(10)
redemption_count = 0

sample_mentees.each do |mentee|
  # Get mentee's total points
  total_points = mentee.total_points
  next if total_points < 15 # Skip if mentee doesn't have enough points

  # Create 1-3 redemptions per mentee
  num_redemptions = rand(1..3)

  num_redemptions.times do
    # Pick an incentive they can afford
    affordable_incentives = incentives.select { |i| i.point_cost <= total_points }
    next if affordable_incentives.empty?

    incentive = affordable_incentives.sample

    # Randomly assign status with weighted probabilities
    status = case rand(100)
    when 0..40 then "approved"     # 40% approved
    when 41..60 then "pending"      # 20% pending
    when 61..80 then "denied"       # 20% denied
    when 81..90 then "deleted"      # 10% deleted (with refund)
    else "deleted_no_refund"         # 10% deleted_no_refund
    end

    # Create redemption with appropriate attributes based on status
    redemption_attrs = {
      mentee: mentee,
      incentive: incentive,
      points_spent: incentive.point_cost,
      status: status,
      created_at: rand(1..30).days.ago
    }

    # Add approved_by and approved_at for approved/denied/deleted statuses
    if %w[approved denied deleted deleted_no_refund].include?(status)
      redemption_attrs[:approved_by] = [admin_user, staff_user].sample
      redemption_attrs[:approved_at] = redemption_attrs[:created_at] + rand(1..3).days
    end

    # Add notes for denied or deleted redemptions
    if status == "denied"
      redemption_attrs[:notes] = ["Insufficient documentation", "Already received this month", "Event not verified"].sample
    elsif status.in?(%w[deleted deleted_no_refund])
      redemption_attrs[:notes] = ["Duplicate redemption", "Staff error", "Student request", "Out of stock"].sample
    end

    Redemption.find_or_create_by!(mentee: mentee, incentive: incentive, created_at: redemption_attrs[:created_at]) do |r|
      r.assign_attributes(redemption_attrs)
    end

    redemption_count += 1

    # Deduct points from available total so they can't redeem more than they have
    total_points -= incentive.point_cost if status.in?(%w[pending approved deleted_no_refund])
  end
end

puts "Created #{redemption_count} sample redemptions"

# Create summary
puts "\n" + "=" * 60
puts "Redemption Test Data Summary"
puts "=" * 60
puts "Incentives available: #{Incentive.count}"
puts "  - Individual: #{Incentive.where(incentive_type: "individual").count}"
puts "  - Team: #{Incentive.where(incentive_type: "team").count}"
puts "Total redemptions: #{Redemption.count}"
puts "  - Pending: #{Redemption.pending.count}"
puts "  - Approved: #{Redemption.approved.count}"
puts "  - Denied: #{Redemption.denied.count}"
puts "  - Deleted (refunded): #{Redemption.where(status: "deleted").count}"
puts "  - Deleted (no refund): #{Redemption.where(status: "deleted_no_refund").count}"
puts "=" * 60

puts "Seeding completed!"
