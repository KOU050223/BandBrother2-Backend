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

ActiveRecord::Schema[8.0].define(version: 2025_06_14_190732) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "battle_details", force: :cascade do |t|
    t.integer "room_id"
    t.text "player_id"
    t.boolean "is_win"
    t.integer "score"
    t.datetime "joined_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "matching_ques", force: :cascade do |t|
    t.text "user_id"
    t.string "status"
    t.integer "room_id"
    t.datetime "enqueued_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "musics", force: :cascade do |t|
    t.string "music_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.string "status"
    t.text "player1_id"
    t.string "player2_id"
    t.integer "music_id"
    t.text "winner_user_id"
    t.datetime "started_at", precision: nil
  end

  create_table "users", force: :cascade do |t|
    t.text "user_id"
    t.string "user_name"
    t.integer "highscore"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
