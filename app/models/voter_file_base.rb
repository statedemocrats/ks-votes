class VoterFileBase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection VOTER_FILES_DB
end
