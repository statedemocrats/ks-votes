class CreateResults < ActiveRecord::Migration[5.1]
  def change
    create_table :results do |t|
      t.integer :votes
      t.integer :precinct_id
      t.integer :office_id
      t.integer :election_id
      t.integer :candidate_id

      t.timestamps
    end
  end
end
