class AddElectionFiles < ActiveRecord::Migration[5.1]
  def change
    add_column(:elections, :election_file_id, :integer)
    add_column(:precincts, :election_file_id, :integer)
    add_column(:offices, :election_file_id, :integer)
    add_column(:candidates, :election_file_id, :integer)
    add_column(:parties, :election_file_id, :integer)
    add_column(:counties, :election_file_id, :integer)
    add_column(:results, :election_file_id, :integer)
  end
end
