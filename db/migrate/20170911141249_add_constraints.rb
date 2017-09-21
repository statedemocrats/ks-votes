class AddConstraints < ActiveRecord::Migration[5.1]
  def change
    add_index(:elections, :name, unique: true)
    add_index(:candidates, [:name, :office_id, :party_id], unique: true)
    add_index(:counties, :name, unique: true)
    add_index(:election_files, :name, unique: true)
    add_index(:offices, [:name, :district], unique: true)
    add_index(:parties, :name, unique: true)
    add_index(:precincts, [:name, :county_id], unique: true)
    add_index(:results, :checksum, unique: true)

    add_foreign_key(:elections, :election_files)
    add_foreign_key(:candidates, :election_files)
    add_foreign_key(:parties, :election_files)
    add_foreign_key(:precincts, :election_files)
    add_foreign_key(:results, :election_files)
    add_foreign_key(:offices, :election_files)
    add_foreign_key(:counties, :election_files)

    add_foreign_key(:results, :precincts)
    add_foreign_key(:results, :offices)
    add_foreign_key(:results, :candidates)
    add_foreign_key(:results, :elections)

    add_foreign_key(:candidates, :offices)
    add_foreign_key(:candidates, :parties)

    add_foreign_key(:precincts, :counties)
  end
end
