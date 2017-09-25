class County < ApplicationRecord
  has_many :precincts
  has_many :census_precincts
end
