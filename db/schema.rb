# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170908163828) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "candidates", force: :cascade do |t|
    t.string "name"
    t.integer "party_id"
    t.integer "office_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
  end

  create_table "counties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
  end

  create_table "election_files", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "elections", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
  end

  create_table "offices", force: :cascade do |t|
    t.string "name"
    t.string "district"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
  end

  create_table "parties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
  end

  create_table "precincts", force: :cascade do |t|
    t.string "name"
    t.integer "county_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
  end

  create_table "results", force: :cascade do |t|
    t.integer "votes"
    t.integer "precinct_id"
    t.integer "office_id"
    t.integer "election_id"
    t.integer "candidate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.string "checksum"
  end

end
