class VoterElectionCode < VoterFileBase
  belongs_to :election_code
  belongs_to :voter
end
