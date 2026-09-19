# This file should ensure the existence of records required to run the application in every environment.
# The code here is idempotent so that it can be executed at any point in every environment.
# The data can be loaded with bin/rails db:seed (or created alongside the database with db:setup).

puts "Seeding database with realistic High Aspirations KC data..."

# ==============================================================================
# 1. TEAMS
# ==============================================================================
puts "\n--- Seeding Teams ---"
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
puts "✓ #{all_teams.size} teams ready"

# Helper method to create user with role profile
def create_user_with_role(email:, first_name:, last_name:, phone_number: nil, password: "Password1!", active: true)
  user = User.find_or_create_by!(email: email.downcase) do |u|
    u.password = password
    u.first_name = first_name
    u.last_name = last_name
    u.phone_number = phone_number
  end
  user.update!(
    active: active,
    first_name: first_name,
    last_name: last_name,
    phone_number: phone_number || user.phone_number
  )
  yield(user) if block_given?
  user
end

# ==============================================================================
# 2. STAFF & ADMINS
# ==============================================================================
puts "\n--- Seeding Staff & Admin Users ---"
admin_user = create_user_with_role(
  email: "admin@example.com",
  first_name: "Darron",
  last_name: "Story",
  phone_number: "(816) 555-0100"
) do |user|
  Staff.find_or_create_by!(user: user) { |s| s.permission_level = :admin }
end

staff_user = create_user_with_role(
  email: "staff@example.com",
  first_name: "Marcus",
  last_name: "Green",
  phone_number: "(816) 555-0101"
) do |user|
  Staff.find_or_create_by!(user: user) { |s| s.permission_level = :standard }
end

coordinator_user = create_user_with_role(
  email: "coordinator@example.com",
  first_name: "David",
  last_name: "Robinson",
  phone_number: "(816) 555-0102"
) do |user|
  Staff.find_or_create_by!(user: user) { |s| s.permission_level = :standard }
end
puts "✓ 3 staff users ready (Darron Story [Admin], Marcus Green, David Robinson)"

# ==============================================================================
# 3. MENTORS & MENTEES (Realistic Names & Data)
# ==============================================================================
puts "\n--- Seeding Mentors & Mentees ---"

# Realistic names pool
mentor_names = [
  ["Dr. Anthony", "Harris"], ["Michael", "Vance"], ["Derrick", "Moore"], ["Brandon", "Clark"],
  ["Terrence", "Wilson"], ["Xavier", "Carter"], ["Kendrick", "Taylor"], ["Darius", "Anderson"],
  ["Jamal", "Thomas"], ["Cameron", "Jackson"], ["Kenneth", "Washington"], ["Andre", "Bell"],
  ["Reggie", "White"], ["Curtis", "Brooks"], ["Reginald", "Foster"], ["Dewayne", "Simmons"],
  ["Keith", "Griffin"], ["Calvin", "Powell"], ["Nathaniel", "Hayes"], ["Cedric", "Bryant"],
  ["Gerald", "Coleman"], ["Lamont", "Howard"], ["Roderick", "Alexander"], ["Tyrone", "Price"],
  ["Russell", "Ross"], ["Warren", "Jenkins"], ["Clifton", "Perry"], ["Darnell", "Butler"],
  ["Byron", "Barnes"], ["Vernon", "Fisher"], ["Maurice", "Henderson"], ["Malcolm", "Patterson"],
  ["Trevor", "Jordan"], ["Donovan", "Hamilton"], ["Phillip", "Graham"], ["Roland", "Reynolds"],
  ["Sherman", "Harrison"], ["Victor", "Gibson"], ["Alvin", "McDonald"], ["Franklin", "Cruz"]
]

mentee_names = [
  ["Jaylen", "Harris"], ["Malik", "Robinson"], ["Deon", "Clark"], ["Kobe", "Lewis"],
  ["Trey", "Walker"], ["Amari", "Hall"], ["Elijah", "Allen"], ["Zion", "Young"],
  ["Isaiah", "King"], ["Devon", "Wright"], ["Jaden", "Scott"], ["Dante", "Torres"],
  ["Marquis", "Nguyen"], ["Tariq", "Hill"], ["Khalil", "Flores"], ["Kameron", "Green"],
  ["Trevor", "Adams"], ["Darian", "Nelson"], ["Omari", "Baker"], ["Justin", "Hall"],
  ["Miles", "Rivera"], ["Micah", "Campbell"], ["Caleb", "Mitchell"], ["Christian", "Roberts"],
  ["Julian", "Carter"], ["Jordan", "Phillips"], ["Corey", "Evans"], ["Bryson", "Turner"],
  ["Keon", "Diaz"], ["Rashad", "Parker"], ["Deandre", "Cruz"], ["Tyree", "Edwards"],
  ["Jalen", "Collins"], ["Damian", "Reyes"], ["Kevon", "Stewart"], ["Demetrius", "Morris"],
  ["Jaquan", "Morales"], ["Tyrese", "Murphy"], ["Donte", "Cook"], ["Tre", "Rogers"],
  ["Jamar", "Gutierrez"], ["Tyrell", "Ortiz"], ["Kendell", "Morgan"], ["Tevin", "Cooper"],
  ["Deshawn", "Peterson"], ["Antwan", "Bailey"], ["Devonte", "Reed"], ["Marquise", "Kelly"],
  ["Raheem", "Howard"], ["Trayvon", "Ramos"], ["Tavon", "Kim"], ["Darius", "Cox"],
  ["Javon", "Ward"], ["Kadeem", "Richardson"], ["Stephon", "Watson"], ["Akeem", "Brooks"],
  ["Hakeem", "Chavez"], ["Tremaine", "Wood"], ["Rashaad", "James"], ["Keshawn", "Bennett"],
  ["Dequan", "Gray"], ["Montrell", "Mendoza"], ["Rico", "Ruiz"], ["Dondre", "Hughes"],
  ["Savon", "Price"], ["Cortez", "Alvarez"], ["Davion", "Castillo"], ["Tyrik", "Sanders"],
  ["Dashawn", "Patel"], ["Keyon", "Myers"], ["Jaheim", "Long"], ["Marcellus", "Ross"],
  ["Trevin", "Foster"], ["Dionte", "Jimenez"], ["Keshon", "Powell"], ["Demarco", "Jenkins"],
  ["Jovon", "Perry"], ["Ronnell", "Russell"], ["Dayvon", "Sullivan"], ["Jacorey", "Bell"],
  ["Tyron", "Coleman"], ["Davonte", "Butler"], ["Latrell", "Henderson"], ["Dangelo", "Barnes"],
  ["Jaleel", "Gonzales"], ["Jordon", "Fisher"], ["Devin", "Vasquez"], ["Kareem", "Simmons"],
  ["Shamar", "Romero"], ["Trae", "Jordan"], ["Quinton", "Patterson"], ["Daquan", "Alexander"],
  ["Denzell", "Hamilton"], ["Tyreek", "Graham"], ["Kesean", "Reynolds"], ["Deonte", "Griffin"],
  ["Jaylon", "Wallace"], ["Darrion", "Moreno"], ["Tray", "West"], ["Montel", "Cole"],
  ["Rayvon", "Hayes"], ["Dequavious", "Bryant"], ["Jalil", "Herrera"], ["Kyree", "Gibson"],
  ["Nigel", "Ellis"], ["Tyshawn", "Tran"], ["Zaire", "Medina"], ["Kelvin", "Aguilar"],
  ["Torrence", "Stevens"], ["Kendall", "Stevenson"], ["Rayshawn", "Dixon"], ["Javen", "Hunt"],
  ["Trevion", "Silva"], ["Koby", "Pearson"], ["Deondre", "Armstrong"], ["Desean", "Fuller"],
  ["Trevor", "Sims"], ["Kyler", "Washington"], ["Darius", "Washington"], ["Malik", "Johnson"],
  ["Jaylen", "Smith"], ["Amari", "Brown"], ["Kobe", "Jones"], ["Elijah", "Davis"],
  ["Zion", "Miller"], ["Isaiah", "Wilson"], ["Jaden", "Moore"], ["Devon", "Taylor"],
  ["Dante", "Anderson"], ["Tariq", "Thomas"], ["Khalil", "Jackson"], ["Kameron", "White"],
  ["Trevor", "Harris"], ["Darian", "Martin"], ["Omari", "Thompson"], ["Miles", "Garcia"],
  ["Micah", "Martinez"], ["Caleb", "Robinson"], ["Christian", "Clark"], ["Julian", "Rodriguez"]
]

all_mentors = []
all_mentees = []
all_mentee_users = []

teams_data = all_teams.map do |team|
  { team: team, label: team.name.sub(" Team", "") }
end

teams_data.each_with_index do |team_data, t_idx|
  team = team_data[:team]
  label = team_data[:label]
  prefix = label.downcase.gsub(/\s+/, "-")

  team_mentors = []

  # 2 mentors per team
  2.times do |m_idx|
    name_pair = mentor_names[(t_idx * 2 + m_idx) % mentor_names.length]
    mentor_user = create_user_with_role(
      email: "#{prefix}.mentor#{m_idx + 1}@example.com",
      first_name: name_pair[0],
      last_name: name_pair[1],
      phone_number: "(816) 555-#{sprintf('%04d', 2000 + t_idx * 10 + m_idx)}"
    ) do |user|
      Mentor.find_or_create_by!(user: user)
    end
    mentor = mentor_user.mentor
    team_mentors << mentor
    all_mentors << mentor
  end

  # 7 mentees per team
  7.times do |m_idx|
    name_pair = mentee_names[(t_idx * 7 + m_idx) % mentee_names.length]
    assigned_mentor = team_mentors[m_idx % team_mentors.length]

    mentee_user = create_user_with_role(
      email: "#{prefix}.mentee#{m_idx + 1}@example.com",
      first_name: name_pair[0],
      last_name: name_pair[1],
      phone_number: "(816) 555-#{sprintf('%04d', 3000 + t_idx * 10 + m_idx)}"
    ) do |user|
      mentee = Mentee.find_or_create_by!(user: user)
      mentee.update!(
        team: team,
        mentor: assigned_mentor,
        enrollment_date: mentee.enrollment_date || (Date.current - (rand(60..400)).days)
      )
    end
    mentee = mentee_user.mentee
    mentee.update!(mentor: assigned_mentor) if mentee.mentor_id.nil?
    all_mentees << mentee
    all_mentee_users << mentee_user
  end
end
puts "✓ #{all_mentors.count} mentors and #{all_mentees.count} mentees ready with assigned teams and mentors"

# ==============================================================================
# 4. GUARDIANS & FAMILY RELATIONSHIPS
# ==============================================================================
puts "\n--- Seeding Guardians & Family Members ---"
guardian_definitions = [
  { email: "blue.parent@example.com", first: "Vanessa", last: "Harris", rel: :parent, mentee_email: "blue.mentee1@example.com" },
  { email: "green.parent@example.com", first: "Keisha", last: "Lewis", rel: :parent, mentee_email: "green.mentee1@example.com" },
  { email: "yellow.parent@example.com", first: "Patricia", last: "Allen", rel: :parent, mentee_email: "yellow.mentee1@example.com" },
  { email: "red.parent@example.com", first: "Brenda", last: "Torres", rel: :parent, mentee_email: "red.mentee1@example.com" },
  { email: "orange.parent@example.com", first: "Carla", last: "Flores", rel: :parent, mentee_email: "orange.mentee1@example.com" },
  { email: "emerald.parent@example.com", first: "Diane", last: "Nelson", rel: :grandparent, mentee_email: "emerald.mentee1@example.com" },
  { email: "teal.parent@example.com", first: "Gloria", last: "Rivera", rel: :parent, mentee_email: "teal.mentee1@example.com" },
  { email: "cyan.parent@example.com", first: "Tanya", last: "Roberts", rel: :parent, mentee_email: "cyan.mentee1@example.com" },
  { email: "sky.parent@example.com", first: "Wanda", last: "Turner", rel: :aunt_uncle, mentee_email: "sky.mentee1@example.com" },
  { email: "indigo.parent@example.com", first: "Joyce", last: "Cruz", rel: :parent, mentee_email: "indigo.mentee1@example.com" },
  { email: "violet.parent@example.com", first: "Angela", last: "Reyes", rel: :parent, mentee_email: "violet.mentee1@example.com" },
  { email: "purple.parent@example.com", first: "Stephanie", last: "Morales", rel: :parent, mentee_email: "purple.mentee1@example.com" },
  { email: "fuchsia.parent@example.com", first: "Rhonda", last: "Rogers", rel: :grandparent, mentee_email: "fuchsia.mentee1@example.com" },
  { email: "pink.parent@example.com", first: "Kimberly", last: "Ortiz", rel: :parent, mentee_email: "pink.mentee1@example.com" },
  { email: "rose.parent@example.com", first: "Monique", last: "Peterson", rel: :parent, mentee_email: "rose.mentee1@example.com" },
  { email: "lime.parent@example.com", first: "Denise", last: "Reed", rel: :parent, mentee_email: "lime.mentee1@example.com" },
  { email: "slate.parent@example.com", first: "Latoya", last: "Ramos", rel: :parent, mentee_email: "slate.mentee1@example.com" },
  { email: "navy.parent@example.com", first: "Evelyn", last: "Ward", rel: :grandparent, mentee_email: "navy.mentee1@example.com" },
  { email: "forest.parent@example.com", first: "Sheryl", last: "Watson", rel: :parent, mentee_email: "forest.mentee1@example.com" },
  { email: "amber.parent@example.com", first: "Cassandra", last: "Wood", rel: :parent, mentee_email: "amber.mentee1@example.com" }
]

guardian_count = 0
family_member_count = 0

guardian_definitions.each_with_index do |defn, idx|
  guardian_user = create_user_with_role(
    email: defn[:email],
    first_name: defn[:first],
    last_name: defn[:last],
    phone_number: "(816) 555-#{sprintf('%04d', 4000 + idx)}"
  ) do |user|
    Guardian.find_or_create_by!(user: user)
  end
  guardian = guardian_user.guardian
  guardian_count += 1

  mentee_user = User.find_by(email: defn[:mentee_email])
  if mentee_user&.mentee && guardian
    FamilyMember.find_or_create_by!(guardian: guardian, mentee: mentee_user.mentee) do |fm|
      fm.relationship_type = defn[:rel]
    end
    family_member_count += 1
  end
end
puts "✓ #{guardian_count} guardians and #{family_member_count} family relationships created"

# ==============================================================================
# 5. VOLUNTEERS
# ==============================================================================
puts "\n--- Seeding Volunteers ---"
volunteers_data = [
  { email: "volunteer.edwards@example.com", first: "James", last: "Edwards" },
  { email: "volunteer.jenkins@example.com", first: "Robert", last: "Jenkins" },
  { email: "volunteer.davis@example.com", first: "Corey", last: "Davis" }
]

volunteers_data.each do |v_data|
  create_user_with_role(email: v_data[:email], first_name: v_data[:first], last_name: v_data[:last]) do |user|
    Volunteer.find_or_create_by!(user: user)
  end
end
puts "✓ #{Volunteer.count} volunteers ready"

# ==============================================================================
# 6. OLYMPIC SEASONS
# ==============================================================================
puts "\n--- Seeding Olympic Seasons ---"
winter_season = OlympicSeason.find_or_create_by!(name: "Winter") do |s|
  s.start_month = 12; s.start_day = 1; s.end_month = 2; s.end_day = 28
end
spring_season = OlympicSeason.find_or_create_by!(name: "Spring") do |s|
  s.start_month = 3; s.start_day = 1; s.end_month = 5; s.end_day = 31
end
summer_season = OlympicSeason.find_or_create_by!(name: "Summer") do |s|
  s.start_month = 6; s.start_day = 1; s.end_month = 8; s.end_day = 31
end
fall_season = OlympicSeason.find_or_create_by!(name: "Fall") do |s|
  s.start_month = 9; s.start_day = 1; s.end_month = 11; s.end_day = 30
end
puts "✓ 4 Olympic Seasons configured"

# ==============================================================================
# 7. EVENT TYPES (Correct point values from the start)
# ==============================================================================
puts "\n--- Seeding Event Types ---"
event_types = {
  "Workshop" => { point_value: 10, category: :org },
  "Mentoring Session" => { point_value: 5, category: :user },
  "Competition" => { point_value: 15, category: :org },
  "Community Service" => { point_value: 20, category: :org },
  "Study Session" => { point_value: 5, category: :user }
}.map do |name, attrs|
  et = EventType.find_or_create_by!(name: name) do |t|
    t.point_value = attrs[:point_value]
    t.category = attrs[:category]
  end
  et.update!(point_value: attrs[:point_value], category: attrs[:category]) if et.point_value != attrs[:point_value]
  et
end
puts "✓ #{event_types.size} event types configured with standard point values (5-20 pts)"

# ==============================================================================
# 8. EVENTS & ATTENDANCE LOGS
# ==============================================================================
puts "\n--- Seeding Saturday Events & Attendance ---"
today = Date.current
current_year = today.year

def saturdays_in_range(start_date, end_date)
  saturdays = []
  current = start_date + ((6 - start_date.wday) % 7)
  while current <= end_date
    saturdays << current
    current += 7.days
  end
  saturdays
end

locations = [
  "High Aspirations Center - Main Hall",
  "Bruce R. Watkins Cultural Center",
  "UMKC Student Union - Room 302",
  "Kansas City Public Library - Central",
  "Penn Valley STEM Lab",
  "Swope Park Community Pavilion"
]

all_events = []
event_counter = 0

seasons_config = [
  { name: "Winter", season: winter_season, start_month: 12, end_month: 2 },
  { name: "Spring", season: spring_season, start_month: 3, end_month: 5 },
  { name: "Summer", season: summer_season, start_month: 6, end_month: 8 },
  { name: "Fall", season: fall_season, start_month: 9, end_month: 11 }
]

seasons_config.each do |s_config|
  if s_config[:start_month] > s_config[:end_month]
    if today.month <= s_config[:end_month]
      start_date = Date.new(current_year - 1, s_config[:start_month], 1)
      end_date = Date.new(current_year, s_config[:end_month], -1)
    else
      start_date = Date.new(current_year, s_config[:start_month], 1)
      end_date = Date.new(current_year + 1, s_config[:end_month], -1)
    end
  else
    start_date = Date.new(current_year, s_config[:start_month], 1)
    end_date = Date.new(current_year, s_config[:end_month], -1)
  end

  saturdays = saturdays_in_range(start_date, end_date)

  saturdays.each_with_index do |saturday, idx|
    et = event_types[event_counter % event_types.length]
    loc = locations[event_counter % locations.length]

    event = Event.find_or_create_by!(event_date: saturday, event_type: et) do |e|
      e.name = "#{s_config[:name]} #{et.name} - Week #{idx + 1}"
      e.description = "#{s_config[:name]} Season #{et.name}: Leadership, character development, and team activities."
      e.location = loc
      e.created_by = [admin_user, staff_user, coordinator_user].sample
    end

    all_events << event
    event_counter += 1
  end
end

past_events = all_events.select { |e| e.event_date < today }
future_events = all_events.select { |e| e.event_date >= today }

registration_count = 0
arrival_count = 0

all_mentee_users.each do |mentee_user|
  # Attend 40-80% of past events to accumulate realistic points (50-180 points)
  attended_events = past_events.sample((past_events.length * rand(0.40..0.85)).round)

  attended_events.each do |event|
    # Registration
    EventLog.find_or_create_by!(event: event, user: mentee_user, log_type: :registered) do |l|
      l.logged_at = event.event_date - rand(3..7).days
      l.points_awarded = 0
    end
    registration_count += 1

    # Arrival (awards points and automatically creates PointLog)
    arrival_log = EventLog.find_or_create_by!(event: event, user: mentee_user, log_type: :arrived) do |l|
      l.logged_at = event.event_date
      l.points_awarded = event.event_type.point_value
    end

    # Ensure PointLog matches correct points
    if arrival_log.point_log
      if arrival_log.point_log.points != event.event_type.point_value
        arrival_log.point_log.update!(points: event.event_type.point_value)
      end
    else
      PointLog.find_or_create_by!(source: arrival_log) do |pl|
        pl.mentee = mentee_user.mentee
        pl.points = event.event_type.point_value
        pl.reason = "Attended #{event.name} on #{event.event_date.strftime("%B %d, %Y")}"
        pl.log_type = "attendance"
      end
    end
    arrival_count += 1
  end

  # Register for 1-2 upcoming events
  future_events.sample([future_events.length, 2].min).each do |event|
    next unless rand < 0.35
    EventLog.find_or_create_by!(event: event, user: mentee_user, log_type: :registered) do |l|
      l.logged_at = today - rand(1..3).days
      l.points_awarded = 0
    end
    registration_count += 1
  end
end
puts "✓ #{all_events.size} Saturday events created across 4 seasons"
puts "✓ #{registration_count} event registrations & #{arrival_count} arrival logs with point awards"

# ==============================================================================
# 9. INCENTIVES & REDEMPTIONS
# ==============================================================================
puts "\n--- Seeding Incentives & Redemptions ---"
incentives_data = [
  { name: "Jack Stack BBQ Gift Card", description: "$25 gift card for Kansas City BBQ", point_cost: 25, incentive_type: "individual" },
  { name: "AMC Theatres Movie Pass", description: "Movie ticket + popcorn voucher", point_cost: 15, incentive_type: "individual" },
  { name: "Minsky's Pizza Voucher", description: "$20 gift card for local gourmet pizza", point_cost: 20, incentive_type: "individual" },
  { name: "Barnes & Noble Book Card", description: "$15 book & educational supplies voucher", point_cost: 15, incentive_type: "individual" },
  { name: "Wilson NCAA Basketball", description: "Official size composite leather basketball", point_cost: 30, incentive_type: "individual" },
  { name: "Under Armour Backpack", description: "Durable school & sports backpack", point_cost: 35, incentive_type: "individual" },
  { name: "GameStop Gift Card", description: "$25 gaming gift card", point_cost: 25, incentive_type: "individual" },
  { name: "Spotify Premium (3-Month)", description: "3-month ad-free music subscription", point_cost: 25, incentive_type: "individual" },
  # Team incentives
  { name: "Team Pizza Celebration", description: "Full team pizza party after Saturday session", point_cost: 100, incentive_type: "team" },
  { name: "Team Main Event Bowling", description: "2 hours of bowling and arcade passes for the team", point_cost: 80, incentive_type: "team" },
  { name: "Private Screening Movie Day", description: "Private auditorium movie outing for team", point_cost: 120, incentive_type: "team" },
  { name: "Swope Park Team BBQ Outing", description: "Catered BBQ cookout and sports day at Swope Park", point_cost: 150, incentive_type: "team" }
]

incentives = incentives_data.map do |data|
  Incentive.find_or_create_by!(name: data[:name]) do |i|
    i.description = data[:description]
    i.point_cost = data[:point_cost]
    i.incentive_type = data[:incentive_type]
    i.created_by = admin_user
    i.active = true
  end
end

# Generate redemptions for mentees with sufficient points
redemption_count = 0
sample_mentees = all_mentees.select { |m| m.total_points >= 15 }

sample_mentees.sample([sample_mentees.length, 30].min).each do |mentee|
  available_points = mentee.total_points
  num_redemptions = rand(1..3)

  num_redemptions.times do
    affordable = incentives.select { |i| i.individual? && i.point_cost <= available_points }
    break if affordable.empty?

    incentive = affordable.sample
    status = case rand(100)
             when 0..50 then "approved"
             when 51..75 then "pending"
             when 76..88 then "denied"
             when 89..94 then "deleted"
             else "deleted_no_refund"
             end

    created_time = rand(2..45).days.ago

    redemption = Redemption.find_or_initialize_by(
      mentee: mentee,
      incentive: incentive,
      created_at: created_time
    )

    if redemption.new_record?
      redemption.assign_attributes(
        points_spent: incentive.point_cost,
        status: status,
        notes: status == "denied" ? "Session attendance requirements not yet met this month" : nil
      )

      if %w[approved denied deleted deleted_no_refund].include?(status)
        redemption.approved_by = [admin_user, staff_user].sample
        redemption.approved_at = created_time + rand(1..3).days
      end

      redemption.save!
      redemption_count += 1
      available_points -= incentive.point_cost if %w[pending approved deleted_no_refund].include?(status)
    end
  end
end
puts "✓ #{incentives.size} incentives configured"
puts "✓ #{Redemption.count} sample redemptions seeded (Approved: #{Redemption.approved.count}, Pending: #{Redemption.pending.count}, Denied: #{Redemption.denied.count})"

# ==============================================================================
# 10. COMMUNITY SERVICE RECORDS
# ==============================================================================
puts "\n--- Seeding Community Service Records ---"
service_activities = [
  { event: "Harvesters Community Food Network", hours: 4.0, description: "Packed emergency food boxes and organized canned goods for local pantries" },
  { event: "Swope Park Trail Clean-Up", hours: 3.5, description: "Cleared brush, collected debris, and beautified walking trails with city parks team" },
  { event: "Urban League Youth Literacy Day", hours: 2.5, description: "Read children's books and helped tutor 2nd and 3rd grade students" },
  { event: "Linwood YMCA Youth Basketball Clinic", hours: 3.0, description: "Assisted coaches with drills and scoreboard operation for youth league" },
  { event: "Kansas City Community Garden Planting", hours: 4.5, description: "Prepared raised garden beds, spread organic compost, and planted vegetables" },
  { event: "Morningstar Senior Center Companion Visit", hours: 2.0, description: "Served breakfast, played chess, and engaged in conversation with seniors" },
  { event: "Back-to-School Backpack Drive", hours: 5.0, description: "Filled and distributed 250 backpacks with essential school supplies for students" },
  { event: "Operation Breakthrough Toy Drive", hours: 3.0, description: "Sorted, wrapped, and categorized holiday gifts for underserved children" }
]

service_count = 0
all_mentees.sample(40).each do |mentee|
  rand(1..3).times do
    activity = service_activities.sample
    event_date = rand(10..120).days.ago.to_date

    CommunityServiceRecord.find_or_create_by!(
      mentee: mentee,
      event: activity[:event],
      event_date: event_date
    ) do |csr|
      csr.hours = activity[:hours]
      csr.description = activity[:description]
      csr.approved = rand < 0.90 # 90% approved, 10% pending/unapproved
    end
    service_count += 1
  end
end
puts "✓ #{CommunityServiceRecord.count} community service records seeded (Approved: #{CommunityServiceRecord.approved.count})"

# ==============================================================================
# 11. MEDIA & GRADE CARDS
# ==============================================================================
puts "\n--- Seeding Media & Grade Cards ---"
# Sample Cloudflare media entries
sample_grade_card_media = 6.times.map do |idx|
  Medium.find_or_create_by!(cloudflare_id: "cf-grade-card-sample-#{idx + 1}") do |m|
    m.filename = "report_card_2026_q#{idx % 4 + 1}.pdf"
    m.media_type = "image"
    m.category = "grade_card"
    m.uploaded_by = admin_user
    m.file_size = 245_000 + rand(10_000..50_000)
    m.content_type = "image/jpeg"
  end
end

grade_descriptions = [
  "Fall 2026 Semester - 3.8 GPA (Honor Roll with Distinction)",
  "Spring 2026 Final Report Card - 3.5 GPA (Principal's Honor Roll)",
  "Q1 Progress Report - All A's and B's (Demonstrated notable improvement in Algebra)",
  "Mid-Year Report Card - 3.4 GPA (Exemplary citizenship and attendance)",
  "Q2 Academic Summary - 3.7 GPA (Advanced Placement History excellence)"
]

grade_card_count = 0
all_mentees.sample(15).each_with_index do |mentee, idx|
  medium = sample_grade_card_media[idx % sample_grade_card_media.length]
  desc = grade_descriptions[idx % grade_descriptions.length]

  GradeCard.find_or_create_by!(mentee: mentee, medium: medium) do |gc|
    gc.description = desc
  end
  grade_card_count += 1
end
puts "✓ #{GradeCard.count} student grade cards seeded"

# ==============================================================================
# 12. SATURDAY SCOOPS (Announcements & Newsletters)
# ==============================================================================
puts "\n--- Seeding Saturday Scoops ---"
scoops_data = [
  {
    title: "Welcome to the Fall 2026 Olympic Season!",
    author: "Darron Story",
    publish_on: 3.weeks.ago.to_date,
    published: true,
    description: "We are kicking off our Fall 2026 season with exciting competitions, inspiring guest speakers, and college readiness workshops. Remember that attendance every Saturday counts toward your team's Olympic standings!"
  },
  {
    title: "Recap: Financial Literacy Workshop with Commerce Bank",
    author: "Marcus Green",
    publish_on: 2.weeks.ago.to_date,
    published: true,
    description: "Our young men gained practical knowledge on checking accounts, compound interest, and investment basics. Big congratulations to the Blue and Emerald Teams for winning the financial quiz competition!"
  },
  {
    title: "Upcoming College Campus Tour: UMKC & Rockhurst University",
    author: "David Robinson",
    publish_on: 1.week.ago.to_date,
    published: true,
    description: "Next Saturday we will be visiting the campuses of UMKC and Rockhurst University. Students will meet admissions officers and tour the engineering and business facilities. Buses depart from the center at 8:30 AM."
  },
  {
    title: "Mentee Academic Honors: 3.5+ GPA Celebrations",
    author: "Darron Story",
    publish_on: 3.days.ago.to_date,
    published: true,
    description: "Congratulations to all the young men who submitted grade cards showcasing 3.5+ GPAs this semester! Keep striving for academic excellence — scholarships and incentive awards await."
  },
  {
    title: "Annual High Aspirations Olympics Championship Preview",
    author: "Marcus Green",
    publish_on: 2.weeks.from_now.to_date,
    published: false,
    description: "The end-of-season championship approaches! Teams are neck-and-neck in point totals. Prepare your team cheers, review your workshop notes, and bring your A-game."
  }
]

scoops_data.each do |data|
  SaturdayScoop.find_or_create_by!(title: data[:title]) do |s|
    s.author = data[:author]
    s.publish_on = data[:publish_on]
    s.published = data[:published]
    s.description = data[:description]
    s.created_by = admin_user
  end
end
puts "✓ #{SaturdayScoop.count} Saturday Scoops seeded (Published: #{SaturdayScoop.published.count})"

# ==============================================================================
# 13. IN-APP MESSAGES & THREADS
# ==============================================================================
puts "\n--- Seeding Messages & Communications ---"

def seed_message_thread(author:, subject:, message:, created_at:, reply_mode: :reply_to_sender, support: false, recipients: [], replies: [])
  root = Message.find_or_initialize_by(
    author: author,
    parent_id: nil,
    subject: subject
  )
  root.message = message
  root.reply_mode = reply_mode
  root.support = support
  root.created_at = created_at
  root.updated_at = created_at
  root.save!

  recipients.each do |r_cfg|
    user = r_cfg[:user]
    next unless user
    mr = MessageRecipient.find_or_initialize_by(message: root, recipient: user)
    mr.is_read = r_cfg.fetch(:is_read, true)
    mr.archived = r_cfg.fetch(:archived, false)
    mr.created_at = created_at
    mr.updated_at = created_at
    mr.save!
  end

  replies.each do |reply_cfg|
    reply_time = reply_cfg[:created_at] || (created_at + 2.hours)
    reply_msg = Message.find_or_initialize_by(
      author: reply_cfg[:author],
      parent: root,
      subject: reply_cfg[:subject] || "Re: #{subject}"
    )
    reply_msg.message = reply_cfg[:message]
    reply_msg.reply_mode = reply_mode
    reply_msg.support = support
    reply_msg.created_at = reply_time
    reply_msg.updated_at = reply_time
    reply_msg.save!

    (reply_cfg[:recipients] || []).each do |r_cfg|
      user = r_cfg[:user]
      next unless user
      mr = MessageRecipient.find_or_initialize_by(message: reply_msg, recipient: user)
      mr.is_read = r_cfg.fetch(:is_read, true)
      mr.archived = r_cfg.fetch(:archived, false)
      mr.created_at = reply_time
      mr.updated_at = reply_time
      mr.save!
    end
  end

  root
end

blue_parent = User.find_by(email: "blue.parent@example.com")
green_parent = User.find_by(email: "green.parent@example.com")
blue_mentor = User.find_by(email: "blue.mentor1@example.com")
green_mentor = User.find_by(email: "green.mentor1@example.com")
blue_mentee = User.find_by(email: "blue.mentee1@example.com")
vol_edwards = User.find_by(email: "volunteer.edwards@example.com")
vol_jenkins = User.find_by(email: "volunteer.jenkins@example.com")

# --- A. INBOX THREADS (Incoming to Admin / Staff) ---

# 1. Unread Support Request from Guardian
seed_message_thread(
  author: blue_parent,
  subject: "Support: Saturday shuttle pickup time at 31st & Troost",
  message: "Good morning Mr. Story and staff, could you please confirm if the shuttle bus will pick up at 31st & Troost at 8:15 AM this Saturday for the STEM workshop? Jaylen wants to make sure he does not miss the bus. Thank you!",
  support: true,
  reply_mode: :reply_to_all,
  created_at: 2.hours.ago,
  recipients: [
    { user: admin_user, is_read: false, archived: false },
    { user: staff_user, is_read: false, archived: false }
  ]
)

# 2. Unread Mentorship Progress Note
seed_message_thread(
  author: blue_mentor,
  subject: "Monthly Mentor Check-In: Blue Team Progress & Tutoring Goals",
  message: "Darron, I wanted to provide a quick update on our Blue Team mentees. Jaylen and Marcus have shown tremendous engagement over the last month. We set up bi-weekly tutoring sessions for Algebra II, and their academic confidence has noticeably improved. I will have their complete SEAS review notes ready by next Tuesday.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 5.hours.ago,
  recipients: [
    { user: admin_user, is_read: false, archived: false }
  ]
)

# 3. Read Mentee Inquiry with Admin Reply and Mentee Follow-up
seed_message_thread(
  author: blue_mentee,
  subject: "Submitting Harvesters Community Service Hours",
  message: "Hi Mr. Story, I completed 4 hours volunteering with the Harvesters Mobile Food Pantry last Saturday. I logged the supervisor confirmation in the portal. Could you please confirm if this qualifies toward the Fall Olympic incentive points?",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 1.day.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: false }
  ],
  replies: [
    {
      author: admin_user,
      subject: "Re: Submitting Harvesters Community Service Hours",
      message: "Excellent work Jaylen! Yes, Harvesters mobile food distribution qualifies for community service points. Your submission has been approved and 20 points have been credited to your account. Keep up the great leadership!",
      created_at: 18.hours.ago,
      recipients: [
        { user: blue_mentee, is_read: true, archived: false }
      ]
    },
    {
      author: blue_mentee,
      subject: "Re: Submitting Harvesters Community Service Hours",
      message: "Thank you so much Mr. Story! Looking forward to Saturday's session.",
      created_at: 12.hours.ago,
      recipients: [
        { user: admin_user, is_read: true, archived: false }
      ]
    }
  ]
)

# 4. Read Support Ticket from Guardian with Staff Resolution
seed_message_thread(
  author: green_parent,
  subject: "Support: Emergency Contact & Dietary Update for Jordan",
  message: "Hello Staff, I recently changed my primary work phone number and wanted to ensure Jordan's emergency profile is updated. My new number is (816) 555-0144. Also, Jordan has a mild peanut allergy that should be noted for catered lunch sessions.",
  support: true,
  reply_mode: :reply_to_all,
  created_at: 2.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: false },
    { user: staff_user, is_read: true, archived: false }
  ],
  replies: [
    {
      author: staff_user,
      subject: "Re: Support: Emergency Contact & Dietary Update for Jordan",
      message: "Thank you Ms. Lewis! I have updated Jordan's emergency contact information in the system and flagged the allergy in our dietary roster for Saturday catering.",
      created_at: 1.day.ago,
      recipients: [
        { user: green_parent, is_read: true, archived: false },
        { user: admin_user, is_read: true, archived: false }
      ]
    }
  ]
)

# 5. Read Volunteer Partnership Proposal
seed_message_thread(
  author: vol_edwards,
  subject: "Volunteer Workshop Proposal: STEM & Drone Technology",
  message: "Good afternoon Mr. Story, Following up on our conversation at the community summit, our engineering team would love to host a 1-hour workshop on drone technology and aviation careers for High Aspirations mentees. Would mid-November work for your Saturday schedule?",
  support: false,
  reply_mode: :reply_to_all,
  created_at: 3.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: false },
    { user: coordinator_user, is_read: true, archived: false }
  ]
)

# 6. Unread Staff Internal Memo
seed_message_thread(
  author: coordinator_user,
  subject: "Staff Memo: October Attendance Metrics & Incentive Eligibility",
  message: "Darron & Marcus, attached is the high-level summary of attendance across all 20 teams for October. Overall attendance is at 91.4%, with Emerald and Navy teams tied for highest consistency. Let me know if you want to review the redemption requests during tomorrow morning's staff meeting.",
  support: false,
  reply_mode: :reply_to_all,
  created_at: 4.hours.ago,
  recipients: [
    { user: admin_user, is_read: false, archived: false },
    { user: staff_user, is_read: true, archived: false }
  ]
)

# 7. Read Mentor Chaperone Availability
seed_message_thread(
  author: green_mentor,
  subject: "Chaperone Availability for UMKC Campus Tour",
  message: "Darron, I have two Green Team mentors available to chaperone the upcoming UMKC tour next Saturday. Do you need additional drivers or will all students be riding the charter buses?",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 4.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: false }
  ]
)

# --- B. SENT THREADS (Authored by Admin) ---

# 8. Broadcast Announcement to Mentees
seed_message_thread(
  author: admin_user,
  subject: "Important: Saturday Session Location Update",
  message: "Good morning everyone! Please note that this Saturday's session will take place at the Bruce R. Watkins Cultural Center Main Hall. Please arrive by 9:00 AM sharp in your team shirts.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 3.days.ago,
  recipients: all_mentee_users.first(25).map { |u| { user: u, is_read: [true, false].sample, archived: false } }
)

# 9. Notice to Mentors regarding SEAS Evaluations
seed_message_thread(
  author: admin_user,
  subject: "Reminder: Fall SEAS Evaluations Due Next Friday",
  message: "Mentors, please remember to complete the quarterly SEAS evaluations for each of your assigned mentees by next Friday at 5:00 PM. Your thoughtful assessments are vital to measuring growth across Social, Emotional, Academic, and Spiritual development domains.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 5.days.ago,
  recipients: all_mentors.first(15).map { |m| { user: m.user, is_read: true, archived: false } }
)

# 10. Letter to Guardians regarding College Tour
seed_message_thread(
  author: admin_user,
  subject: "Upcoming College Campus Tour: UMKC & Rockhurst University",
  message: "Dear High Aspirations Parents and Guardians, Next Saturday, our young men will visit UMKC and Rockhurst University. Transportation, campus tours, and lunch will be provided. Please make sure your mentee's digital permission slip is submitted by Wednesday evening.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 1.week.ago,
  recipients: Guardian.first(15).map { |g| { user: g.user, is_read: true, archived: false } }
)

# 11. Staff Directive regarding Incentive Store
seed_message_thread(
  author: admin_user,
  subject: "Staff Directive: Updated Incentive Point Catalog & Guidelines",
  message: "Marcus and David, I have finalized the new catalog items including the KC Current and Sporting KC ticket bundles, as well as the STEM robotics kits. Please review the redemption approval workflow so we maintain quick turnaround times for students redeeming rewards.",
  support: false,
  reply_mode: :reply_to_all,
  created_at: 2.weeks.ago,
  recipients: [
    { user: staff_user, is_read: true, archived: false },
    { user: coordinator_user, is_read: true, archived: false }
  ]
)

# 12. Recognition to Mentor
seed_message_thread(
  author: admin_user,
  subject: "Thank You: Outstanding Leadership at Career Workshop",
  message: "Dr. Harris, thank you for leading the medical and healthcare careers roundtable last Saturday. The mentees were thoroughly engaged and several expressed great enthusiasm about biomedical science.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 3.weeks.ago,
  recipients: [
    { user: blue_mentor, is_read: true, archived: false }
  ]
)

# --- C. ARCHIVED THREADS (Archived by Admin & Staff) ---

# 13. Summer 2026 Olympic Season Wrap-Up & Points Certification
seed_message_thread(
  author: coordinator_user,
  subject: "Summer 2026 Olympic Season Wrap-Up & Trophy Presentation",
  message: "Mr. Story, all point logs and event attendance for the Summer 2026 season have been certified. The Blue Team finished in first place with 1,420 total points, followed closely by the Emerald Team with 1,380. All trophy engravings are complete and ready for the awards banquet.",
  support: false,
  reply_mode: :reply_to_all,
  created_at: 45.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: true },
    { user: staff_user, is_read: true, archived: true }
  ]
)

# 14. Resolved Support Inquiry: September Shuttle Route Confirmation
seed_message_thread(
  author: blue_parent,
  subject: "Support: September Saturday Shuttle Bus Confirmation",
  message: "Hello, I wanted to confirm that Jaylen is on the shuttle bus list from the 31st & Troost stop for the September kickoff meeting. Thank you!",
  support: true,
  reply_mode: :reply_to_all,
  created_at: 35.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: true },
    { user: staff_user, is_read: true, archived: true }
  ],
  replies: [
    {
      author: staff_user,
      subject: "Re: Support: September Saturday Shuttle Bus Confirmation",
      message: "Confirmed! Jaylen is on the list and Coach Vance will be at the stop by 8:15 AM.",
      created_at: 35.days.ago + 2.hours,
      recipients: [
        { user: blue_parent, is_read: true, archived: false },
        { user: admin_user, is_read: true, archived: true }
      ]
    }
  ]
)

# 15. Facility Coordination: Swope Park Pavilion Permit
seed_message_thread(
  author: vol_jenkins,
  subject: "Confirmed: Swope Park Pavilion Permit #KC-2026-4412",
  message: "Darron, KC Parks and Recreation has approved our pavilion reservation for the Annual Fall BBQ and Sports Challenge. The permit copy has been filed in the front office and park rangers have been notified.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 60.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: true }
  ]
)

# 16. Fall Volunteer Background Check Clearances
seed_message_thread(
  author: coordinator_user,
  subject: "Fall 2026 Volunteer Background Check Clearances",
  message: "Darron, all new community volunteers have passed their criminal background screenings and completed the mentor orientation modules. Their profiles are marked active in the system.",
  support: false,
  reply_mode: :reply_to_all,
  created_at: 50.days.ago,
  recipients: [
    { user: admin_user, is_read: true, archived: true },
    { user: staff_user, is_read: true, archived: true }
  ]
)

# --- D. DIRECT MENTOR-MENTEE THREAD ---
seed_message_thread(
  author: blue_mentor,
  subject: "Checking in on this week's school goals",
  message: "Hey Jaylen, great job on your presentation last Saturday! How are things going with your math midterm prep this week? Let me know if you need to schedule a study session.",
  support: false,
  reply_mode: :reply_to_sender,
  created_at: 6.days.ago,
  recipients: [
    { user: blue_mentee, is_read: true, archived: false }
  ],
  replies: [
    {
      author: blue_mentee,
      subject: "Re: Checking in on this week's school goals",
      message: "Thanks Dr. Harris! I finished the chapter review and feel ready for Friday's test. Looking forward to Saturday's robotics workshop!",
      created_at: 5.days.ago,
      recipients: [
        { user: blue_mentor, is_read: true, archived: false }
      ]
    }
  ]
)

puts "✓ In-app messaging threads seeded across Inbox, Sent, and Archived (17 threads, #{Message.count} total messages)"

# ==============================================================================
# 14. SEAS EVALUATIONS & RESPONSES
# ==============================================================================
puts "\n--- Seeding SEAS Evaluations & Scores ---"
seas_domains_data = {
  "Social" => {
    position: 1,
    description: "Peer relationships, leadership, and community interaction",
    questions: [
      "Actively participates in team activities and Saturday discussions",
      "Demonstrates respectful communication with mentors, staff, and peers",
      "Shows constructive problem-solving and conflict resolution skills"
    ]
  },
  "Emotional" => {
    position: 2,
    description: "Self-awareness, emotional regulation, and resilience",
    questions: [
      "Manages frustration and adversity in positive, productive ways",
      "Expresses feelings and concerns respectfully and constructively",
      "Displays empathy, consideration, and encouragement toward others"
    ]
  },
  "Academic" => {
    position: 3,
    description: "Scholastic commitment, goal setting, and study habits",
    questions: [
      "Submits grade cards on schedule and demonstrates academic effort",
      "Sets measurable goals for school performance and career exploration",
      "Proactively seeks tutoring, mentoring, or academic assistance when needed"
    ]
  },
  "Spiritual" => {
    position: 4,
    description: "Moral foundation, personal values, and integrity",
    questions: [
      "Reflects consistently on personal integrity, values, and purpose",
      "Makes responsible choices under peer pressure and in difficult situations",
      "Acts as a positive, uplifting role model for younger students"
    ]
  }
}

all_questions = []

seas_domains_data.each do |domain_name, data|
  domain = SeasDomain.find_or_create_by!(name: domain_name) do |d|
    d.position = data[:position]
    d.description = data[:description]
  end
  domain.update!(description: data[:description]) if domain.description.nil?

  data[:questions].each_with_index do |text, q_idx|
    question = SeasQuestion.find_or_create_by!(seas_domain: domain, position: q_idx + 1) do |q|
      q.text = text
    end
    question.update!(text: text) if question.text != text
    all_questions << question
  end
end

# Seed SEAS evaluations in various stages
all_mentees.first(20).each_with_index do |mentee, idx|
  eval_status = case idx % 5
                when 0 then "reviewed"
                when 1 then "reviewed"
                when 2 then "in_review"
                when 3 then "submitted"
                else "in_progress"
                end

  evaluation = SeasEvaluation.find_or_initialize_by(
    mentee: mentee,
    evaluation_year: current_year
  )

  if evaluation.new_record?
    evaluation.status = eval_status
    evaluation.sent_at = rand(30..90).days.ago

    if %w[submitted in_review reviewed].include?(eval_status)
      evaluation.completed_at = evaluation.sent_at + rand(5..15).days
    end

    if eval_status == "reviewed"
      evaluation.reviewer = staff_user
      evaluation.reviewed_at = evaluation.completed_at + rand(2..5).days
    end

    evaluation.save!

    # Create responses for completed / reviewed evaluations
    if %w[submitted in_review reviewed].include?(eval_status)
      all_questions.each do |q|
        score = rand(2..3)
        resp = SeasResponse.find_or_create_by!(seas_evaluation: evaluation, seas_question: q) do |r|
          r.score = score
          if eval_status == "reviewed"
            r.review_action = rand < 0.20 ? "adjusted" : "confirmed"
            r.adjusted_score = r.review_action == "adjusted" ? [score + 1, 3].min : score
            r.feedback = [
              "Demonstrates outstanding consistency in this area.",
              "Continues to show steady growth and positive leadership.",
              "Active contributor during team reflections.",
              "Excellent attitude and mentorship to younger peers."
            ].sample
          end
        end
      end
      evaluation.update_snapshot_with_scores!
      evaluation.update_snapshot_with_review_data! if eval_status == "reviewed"
    end
  end
end
puts "✓ #{SeasDomain.count} SEAS domains & #{SeasQuestion.count} questions verified"
puts "✓ #{SeasEvaluation.count} SEAS evaluations seeded (Reviewed: #{SeasEvaluation.where(status: 'reviewed').count}, Submitted: #{SeasEvaluation.where(status: 'submitted').count})"

# Set default SEAS settings
SeasSetting.set("current_evaluation_year", current_year.to_s)
SeasSetting.set("evaluation_instructions", "Please evaluate each question honestly on a scale of 0 to 3 based on your observations over the current program year.")

# ==============================================================================
# SUMMARY REPORT
# ==============================================================================
puts "\n" + "=" * 65
puts "🎉 HIGH ASPIRATIONS KC - SEED DATA SUMMARY"
puts "=" * 65
puts "Teams:                     #{Team.count}"
puts "Staff & Admins:            #{Staff.count}"
puts "Mentors:                   #{Mentor.count}"
puts "Mentees:                   #{Mentee.count}"
puts "Guardians:                 #{Guardian.count}"
puts "Family Relationships:      #{FamilyMember.count}"
puts "Volunteers:                #{Volunteer.count}"
puts "Events (4 Seasons):        #{Event.count}"
puts "Event Attendance Logs:     #{EventLog.where(log_type: :arrived).count}"
puts "Total Point Logs:          #{PointLog.count}"
puts "Incentives:                #{Incentive.count}"
puts "Redemptions:               #{Redemption.count} (Pending: #{Redemption.pending.count}, Approved: #{Redemption.approved.count})"
puts "Community Service Records: #{CommunityServiceRecord.count} (Approved: #{CommunityServiceRecord.approved.count})"
puts "Grade Cards:               #{GradeCard.count}"
puts "Saturday Scoops:           #{SaturdayScoop.count}"
puts "Messages / Conversations:  #{Message.roots.count} threads (#{Message.count} total messages)"
puts "SEAS Evaluations:          #{SeasEvaluation.count} (#{SeasEvaluation.where(status: 'reviewed').count} reviewed)"
puts "=" * 65
puts "Seeding completed successfully!\n"
