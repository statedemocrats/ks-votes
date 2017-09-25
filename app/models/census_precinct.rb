class CensusPrecinct < ApplicationRecord
  belongs_to :county
  has_many :precincts
end
