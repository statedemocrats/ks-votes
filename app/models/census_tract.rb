class CensusTract < ApplicationRecord
  belongs_to :county
  has_many :census_precincts
  has_many :precincts, through: :census_precincts
  has_one :precinct
end
