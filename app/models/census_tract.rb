class CensusTract < ApplicationRecord
  belongs_to :county

  # m2m join table
  has_many :census_precincts

  # m2m target table
  has_many :overlapping_precincts, through: :census_precincts

  # o2m primary assignment
  has_many :precincts

  # most common primary assignment (< 1% have 2+)
  has_one :precinct

  enum reason: { census: 0, curated: 1, sos: 2 }

  def self.find_by_vtd_2012(vtd)
    m = vtd.match(/^20(\d\d\d)(\w\w\w\w\w\w)$/)
    includes(:county).where(counties: {fips: m[1]}).where(vtd_code: m[2]).first
  end
end
