class CensusPrecinct < ApplicationRecord
  belongs_to :county
  has_many :precincts
  has_many :precinct_aliases
end
