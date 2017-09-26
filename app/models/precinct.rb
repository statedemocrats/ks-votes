class Precinct < ApplicationRecord
  belongs_to :county
  belongs_to :census_precinct
end
