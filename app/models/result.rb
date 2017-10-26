class Result < ApplicationRecord
  belongs_to :precinct
  belongs_to :office
  belongs_to :election
  belongs_to :candidate
  belongs_to :election_file

  scope :full, -> { includes([:election, :office, { candidate: :party }]) }

  # why the Precinct was chosen for this Result
  enum reason: { vtd: 0, finder: 1 }
end
