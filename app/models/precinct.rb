class Precinct < ApplicationRecord
  belongs_to :county
  belongs_to :census_tract, optional: true
  has_many :census_precincts
  has_many :census_tracts, through: :census_precincts
  has_many :precinct_aliases
  has_many :results

  def has_alias?(name)
    alias_names.any? { |n| n == name }
  end

  def alias_names
    precinct_aliases.pluck(:name)
  end

  def self.find_by_any_name(name, county_id=nil)
    pas = PrecinctAlias.includes(:precinct).where('lower(precinct_aliases.name) IN (?)', [name.downcase])
    ps = Precinct.where('lower(name) IN (?)', [name.downcase])
    matches = [ps, pas.collect(&:precinct)].flatten.uniq.sort_by {|p| p.created_at }
    if county_id
      matches.select {|p| p.county_id == county_id }
    else
      matches
    end
  end
end
