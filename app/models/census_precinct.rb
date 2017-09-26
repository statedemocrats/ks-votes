class CensusPrecinct < ApplicationRecord
  belongs_to :precinct
  belongs_to :census_tract
end
