class PrecinctAlias < ApplicationRecord
  belongs_to :precinct

  enum reason: { curated: 0, orphan: 1, finder: 2 }
end
