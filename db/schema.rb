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

ActiveRecord::Schema.define(version: 20170911141249) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "candidates", force: :cascade do |t|
    t.string "name"
    t.integer "party_id"
    t.integer "office_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.index ["name", "office_id", "party_id"], name: "index_candidates_on_name_and_office_id_and_party_id", unique: true
  end

  create_table "counties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.index ["name"], name: "index_counties_on_name", unique: true
  end

  create_table "election_files", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_election_files_on_name", unique: true
  end

  create_table "elections", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.index ["name"], name: "index_elections_on_name", unique: true
  end

  create_table "offices", force: :cascade do |t|
    t.string "name"
    t.string "district"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.index ["name", "district"], name: "index_offices_on_name_and_district", unique: true
  end

  create_table "parties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.index ["name"], name: "index_parties_on_name", unique: true
  end

  create_table "precincts", force: :cascade do |t|
    t.string "name"
    t.integer "county_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.index ["name", "county_id"], name: "index_precincts_on_name_and_county_id", unique: true
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
    t.index ["checksum"], name: "index_results_on_checksum", unique: true
  end

  add_foreign_key "candidates", "election_files"
  add_foreign_key "candidates", "offices"
  add_foreign_key "candidates", "parties"
  add_foreign_key "counties", "election_files"
  add_foreign_key "elections", "election_files"
  add_foreign_key "offices", "election_files"
  add_foreign_key "parties", "election_files"
  add_foreign_key "precincts", "counties"
  add_foreign_key "precincts", "election_files"
  add_foreign_key "results", "candidates"
  add_foreign_key "results", "election_files"
  add_foreign_key "results", "elections"
  add_foreign_key "results", "offices"
  add_foreign_key "results", "precincts"
end