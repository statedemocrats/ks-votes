class CensusTract < ApplicationRecord
  belongs_to :county

  # m2m join table
  has_many :census_precincts

  # m2m target table
  has_many :overlapping_precincts, through: :census_precincts, source: "precinct"

  # o2m primary assignment
  has_many :precincts

  # most common primary assignment (< 1% have 2+)
  has_one :precinct

  enum reason: { census: 0, curated: 1, sos: 2 }

  def self.find_by_vtd_2012(vtd)
    m = vtd.match(/^20(\d\d\d)(\w\w\w\w\w\w)$/)
    includes(:county).where(counties: {fips: m[1]}).where(vtd_code: m[2]).first
  end

  def map_id
    county.vtd_for(vtd_code)
  end

  def voters
    pt_code = "PT#{vtd_code}"
    Voter.where(county: county.name).where(%Q((vtd='#{vtd_code}' OR districts @> '{"pt":"#{pt_code}"}'::jsonb) OR precinct IN (?)), alt_names)
  end

  def each_voter(&block)
    voters.find_in_batches do |vs|
      vs.each do |voter|
        yield(voter)
      end
    end
  end

  def alt_names
    [precinct&.name, precinct&.alias_names].flatten.uniq
  end

  def overlapping_names
    overlapping_precincts.map { |p| p.alias_names }.flatten.uniq
  end
end
