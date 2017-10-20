class County < ApplicationRecord
  has_many :precincts
  has_many :census_tracts

  def self.n(name)
    find_by(name: name)
  end
end
