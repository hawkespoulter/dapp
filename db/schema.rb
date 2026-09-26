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

ActiveRecord::Schema[7.1].define(version: 2026_09_26_000006) do
  create_table "area_states", force: :cascade do |t|
    t.integer "game_id", null: false
    t.string "area", null: false
    t.string "owner", default: "neutral", null: false
    t.integer "strength", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "area"], name: "index_area_states_on_game_id_and_area", unique: true
    t.index ["game_id"], name: "index_area_states_on_game_id"
  end

  create_table "attractions", force: :cascade do |t|
    t.string "name"
    t.string "park"
    t.string "area"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "challenges", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "reward", default: 1, null: false
    t.string "park"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "list_from"
    t.integer "list_count"
    t.index ["park"], name: "index_challenges_on_park"
    t.index ["title"], name: "index_challenges_on_title", unique: true
  end

  create_table "game_events", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "player_id"
    t.string "kind", null: false
    t.string "message", null: false
    t.json "data", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_events_on_game_id"
    t.index ["player_id"], name: "index_game_events_on_player_id"
  end

  create_table "game_presets", force: :cascade do |t|
    t.string "key", null: false
    t.integer "position", default: 0, null: false
    t.json "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_game_presets_on_key", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.string "join_code", null: false
    t.string "park", null: false
    t.string "villain_key", null: false
    t.string "preset", null: false
    t.string "status", default: "lobby", null: false
    t.string "result"
    t.datetime "started_at"
    t.datetime "ends_at"
    t.datetime "next_tick_at"
    t.integer "tick_count", default: 0, null: false
    t.integer "escalation", default: 0, null: false
    t.integer "outbreaks", default: 0, null: false
    t.integer "coins", default: 0, null: false
    t.integer "influence_stash", default: 0, null: false
    t.json "villain_draw", default: [], null: false
    t.json "villain_discard", default: [], null: false
    t.json "challenge_discard", default: [], null: false
    t.json "rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["join_code"], name: "index_games_on_join_code", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.integer "game_id", null: false
    t.string "name", null: false
    t.string "auth_token", null: false
    t.boolean "host", default: false, null: false
    t.integer "coins", default: 0, null: false
    t.json "hand", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "card_lists", default: {}, null: false
    t.index ["auth_token"], name: "index_players_on_auth_token", unique: true
    t.index ["game_id"], name: "index_players_on_game_id"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name"
    t.string "park"
    t.string "area"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shows", force: :cascade do |t|
    t.string "name"
    t.string "park"
    t.string "area"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "area_states", "games"
  add_foreign_key "game_events", "games"
  add_foreign_key "game_events", "players"
  add_foreign_key "players", "games"
end
