# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_10_072915) do
  create_table "event_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "participated_at", null: false
    t.integer "points_awarded", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_event_logs_on_event_id"
    t.index ["user_id"], name: "index_event_logs_on_user_id"
  end

  create_table "event_registrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "registration_date", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id", "user_id"], name: "index_event_registrations_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_event_registrations_on_event_id"
    t.index ["registration_date"], name: "index_event_registrations_on_registration_date"
    t.index ["user_id"], name: "index_event_registrations_on_user_id"
  end

  create_table "event_types", force: :cascade do |t|
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "point_value", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_event_types_on_name", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.text "description"
    t.datetime "event_date", null: false
    t.integer "event_type_id", null: false
    t.string "image_url"
    t.string "location"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["event_date"], name: "index_events_on_event_date"
    t.index ["event_type_id"], name: "index_events_on_event_type_id"
  end

  create_table "olympic_seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_day", null: false
    t.integer "end_month", null: false
    t.string "name", null: false
    t.integer "start_day", null: false
    t.integer "start_month", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.integer "color", null: false
    t.datetime "created_at", null: false
    t.string "icon_url"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "test_models", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_name"
    t.string "token_hash", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token_hash"], name: "index_tokens_on_token_hash", unique: true
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "user_relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "related_user_id", null: false
    t.integer "relationship_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["related_user_id"], name: "index_user_relationships_on_related_user_id"
    t.index ["user_id", "related_user_id"], name: "index_user_relationships_on_user_id_and_related_user_id", unique: true
    t.index ["user_id"], name: "index_user_relationships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.string "avatar_url"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.integer "role", default: 5, null: false
    t.integer "team_id"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "event_logs", "events"
  add_foreign_key "event_logs", "users"
  add_foreign_key "event_registrations", "events"
  add_foreign_key "event_registrations", "users"
  add_foreign_key "events", "event_types"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "tokens", "users"
  add_foreign_key "user_relationships", "users"
  add_foreign_key "user_relationships", "users", column: "related_user_id"
  add_foreign_key "users", "teams"
end
