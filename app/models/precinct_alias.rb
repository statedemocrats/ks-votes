class PrecinctAlias < ApplicationRecord
  belongs_to :precinct

  enum reason: { curated: 0, orphan: 1, finder: 2 }

  def self.l(name)
    where('lower(name) IN (?)', [name.downcase]).first
  end
end
