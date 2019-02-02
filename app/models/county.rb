class County < ApplicationRecord
  has_many :precincts
  has_many :census_tracts

  def self.n(name)
    find_by(name: name)
  end

  def self.l(name)
    where('lower(name) = ?', [name.downcase]).first
  end

  def vtd_for(vtd)
    "20#{fips}#{vtd}"
  end

  def precinct_matching(str)
    Precinct.find_by_any_name(str, id)
  end

  def precinct_names
    precincts.map(&:name)
  end
end
