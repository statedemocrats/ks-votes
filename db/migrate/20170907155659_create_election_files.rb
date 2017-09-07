class CreateElectionFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :election_files do |t|
      t.string :name
      t.timestamps
    end
  end
end
