class Candidate < ApplicationRecord
  belongs_to :party
  belongs_to :election_file
end
