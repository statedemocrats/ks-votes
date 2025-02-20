# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_08_211456) do

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

  create_table "census_precincts", force: :cascade do |t|
    t.bigint "precinct_id"
    t.bigint "census_tract_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["census_tract_id"], name: "index_census_precincts_on_census_tract_id"
    t.index ["precinct_id"], name: "index_census_precincts_on_precinct_id"
  end

  create_table "census_tracts", force: :cascade do |t|
    t.integer "county_id"
    t.string "name"
    t.string "vtd_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reason"
    t.string "year"
    t.string "geosha"
    t.index ["geosha"], name: "index_census_tracts_on_geosha"
    t.index ["vtd_code", "county_id", "year"], name: "index_census_tracts_on_vtd_code_and_county_id_and_year", unique: true
    t.index ["vtd_code"], name: "index_census_tracts_on_vtd_code"
  end

  create_table "counties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.string "fips"
    t.index ["fips"], name: "index_counties_on_fips", unique: true
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

  create_table "precinct_aliases", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "precinct_id"
    t.integer "reason"
    t.index "lower((name)::text)", name: "precinct_aliases_lower_name_idx"
    t.index ["name", "precinct_id"], name: "index_precinct_aliases_on_name_and_precinct_id", unique: true
    t.index ["precinct_id"], name: "index_precinct_aliases_on_precinct_id"
  end

  create_table "precincts", force: :cascade do |t|
    t.string "name"
    t.integer "county_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_file_id"
    t.integer "census_tract_id"
    t.index "lower((name)::text)", name: "precincts_lower_name_idx"
    t.index ["name", "county_id", "census_tract_id"], name: "index_precincts_on_name_and_county_id_and_census_tract_id", unique: true
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
    t.integer "reason"
    t.index ["checksum"], name: "index_results_on_checksum", unique: true
  end

  add_foreign_key "candidates", "election_files"
  add_foreign_key "candidates", "offices"
  add_foreign_key "candidates", "parties"
  add_foreign_key "census_tracts", "counties"
  add_foreign_key "counties", "election_files"
  add_foreign_key "elections", "election_files"
  add_foreign_key "offices", "election_files"
  add_foreign_key "parties", "election_files"
  add_foreign_key "precinct_aliases", "precincts"
  add_foreign_key "precincts", "census_tracts"
  add_foreign_key "precincts", "counties"
  add_foreign_key "precincts", "election_files"
  add_foreign_key "results", "candidates"
  add_foreign_key "results", "election_files"
  add_foreign_key "results", "elections"
  add_foreign_key "results", "offices"
  add_foreign_key "results", "precincts"
end
