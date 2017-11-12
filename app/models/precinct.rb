class Precinct < ApplicationRecord
  belongs_to :county
  belongs_to :election_file, optional: true
  belongs_to :census_tract, optional: true
  has_many :census_precincts
  has_many :census_tracts, through: :census_precincts
  has_many :precinct_aliases
  has_many :results

  def votes_cast
    cast = 0
    results.each { |r| cast += r.votes }
    cast
  end

  def election_names
    results.full.map { |r| r.election.name }.uniq
  end

  def has_alias?(name)
    alias_names.any? { |n| n == name }
  end

  def looks_like?(name)
    has_alias?(name) || self.name == name
  end

  def alias_names
    precinct_aliases.pluck(:name)
  end

  def census_tract_vtds
    vtds = census_tracts.map { |ct| ct.vtd_code }
    vtds << census_tract.vtd_code if census_tract
    vtds.uniq
  end

  def map_id
    census_tract_vtds.map { |vtd| "20#{county.fips}#{vtd}" }.join(':')
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

  def self.find_best(name, county_id=nil)
    find_by_any_name(name, county_id).first
  end
end
