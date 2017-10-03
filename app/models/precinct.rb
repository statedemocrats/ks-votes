class Precinct < ApplicationRecord
  belongs_to :county
  belongs_to :census_tract, optional: true
  has_many :census_precincts
  has_many :census_tracts, through: :census_precincts
  has_many :precinct_aliases
  has_many :results

  def has_alias?(name)
    precinct_aliases.pluck(:name).any? { |n| n == name }
  end
end
