class Precinct < ApplicationRecord
  belongs_to :county
  has_many :census_precincts
  has_many :census_tracts, through: :census_precincts
  has_many :precinct_aliases
end
