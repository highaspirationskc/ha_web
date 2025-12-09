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

ActiveRecord::Schema[8.1].define(version: 2025_12_09_190157) do
  create_table "event_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "log_type", default: "registered", null: false
    t.datetime "logged_at", null: false
    t.integer "points_awarded", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_event_logs_on_event_id"
    t.index ["event_id"], name: "index_event_logs_on_event_id_and_log_type"
    t.index ["user_id"], name: "index_event_logs_on_user_id"
  end

  create_table "event_types", force: :cascade do |t|
    t.string "category", null: false
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
    t.integer "image_id"
    t.string "location"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["event_date"], name: "index_events_on_event_date"
    t.index ["event_type_id"], name: "index_events_on_event_type_id"
    t.index ["image_id"], name: "index_events_on_image_id"
  end

  create_table "family_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "guardian_id", null: false
    t.integer "mentee_id", null: false
    t.string "relationship_type", null: false
    t.datetime "updated_at", null: false
    t.index ["guardian_id", "mentee_id"], name: "index_family_members_on_guardian_id_and_mentee_id", unique: true
    t.index ["guardian_id"], name: "index_family_members_on_guardian_id"
    t.index ["mentee_id"], name: "index_family_members_on_mentee_id"
  end

  create_table "guardians", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_guardians_on_user_id", unique: true
  end

  create_table "media", force: :cascade do |t|
    t.string "alt_text"
    t.string "category", default: "general", null: false
    t.string "cloudflare_id", null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.integer "file_size"
    t.string "filename", null: false
    t.integer "height"
    t.string "media_type", default: "image", null: false
    t.datetime "updated_at", null: false
    t.integer "uploaded_by_id", null: false
    t.integer "width"
    t.index ["category"], name: "index_media_on_category"
    t.index ["cloudflare_id"], name: "index_media_on_cloudflare_id", unique: true
    t.index ["media_type"], name: "index_media_on_media_type"
    t.index ["uploaded_by_id"], name: "index_media_on_uploaded_by_id"
  end

  create_table "mentees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mentor_id"
    t.integer "team_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["mentor_id"], name: "index_mentees_on_mentor_id"
    t.index ["team_id"], name: "index_mentees_on_team_id"
    t.index ["user_id"], name: "index_mentees_on_user_id", unique: true
  end

  create_table "mentors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_mentors_on_user_id", unique: true
  end

  create_table "message_recipients", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "is_read", default: false, null: false
    t.integer "message_id", null: false
    t.integer "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "recipient_id"], name: "index_message_recipients_on_message_id_and_recipient_id", unique: true
    t.index ["message_id"], name: "index_message_recipients_on_message_id"
    t.index ["recipient_id", "is_read"], name: "index_message_recipients_on_recipient_id_and_is_read"
    t.index ["recipient_id"], name: "index_message_recipients_on_recipient_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.integer "parent_id"
    t.integer "reply_mode", default: 1, null: false
    t.string "subject", null: false
    t.boolean "support", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["parent_id"], name: "index_messages_on_parent_id"
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

  create_table "staff", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission_level", default: "standard", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_staff_on_user_id", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.integer "icon_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["icon_id"], name: "index_teams_on_icon_id"
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

  create_table "user_devices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_name"
    t.string "fcm_token", null: false
    t.string "platform", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["fcm_token"], name: "index_user_devices_on_fcm_token", unique: true
    t.index ["user_id"], name: "index_user_devices_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.integer "avatar_id"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.index ["avatar_id"], name: "index_users_on_avatar_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "volunteers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_volunteers_on_user_id", unique: true
  end

  add_foreign_key "events", "event_types"
  add_foreign_key "events", "media", column: "image_id"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "family_members", "guardians"
  add_foreign_key "family_members", "mentees"
  add_foreign_key "guardians", "users"
  add_foreign_key "media", "users", column: "uploaded_by_id"
  add_foreign_key "mentees", "mentors"
  add_foreign_key "mentees", "teams"
  add_foreign_key "mentees", "users"
  add_foreign_key "mentors", "users"
  add_foreign_key "message_recipients", "messages"
  add_foreign_key "message_recipients", "users", column: "recipient_id"
  add_foreign_key "messages", "messages", column: "parent_id"
  add_foreign_key "messages", "users", column: "author_id"
  add_foreign_key "staff", "users"
  add_foreign_key "teams", "media", column: "icon_id"
  add_foreign_key "tokens", "users"
  add_foreign_key "user_devices", "users"
  add_foreign_key "users", "media", column: "avatar_id"
  add_foreign_key "volunteers", "users"
end
