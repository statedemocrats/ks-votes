class Result < ApplicationRecord
  belongs_to :precinct
  belongs_to :office
  belongs_to :election
  belongs_to :candidate
  belongs_to :election_file
end