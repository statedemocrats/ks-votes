class ChangePrecinctCensusToM2M < ActiveRecord::Migration[5.1]
  def change
    create_table :census_tracts do |t|
      t.integer :county_id
      t.string :name
      t.string :vtd_code

      t.timestamps
    end

    add_index(:census_tracts, [:vtd_code, :county_id], unique: true)
    add_foreign_key(:census_tracts, :counties)

    remove_foreign_key(:precincts, :census_precincts)
    remove_foreign_key(:precinct_aliases, :census_precincts)
    remove_column(:precincts, :census_precinct_id)
    remove_column(:precinct_aliases, :census_precinct_id)
    add_column(:precinct_aliases, :precinct_id, :integer)
    add_index(:precinct_aliases, :precinct_id)
    add_foreign_key(:precinct_aliases, :precincts)

    drop_table(:census_precincts)

    create_table :census_precincts do |t|
      t.belongs_to :precinct, index: true
      t.belongs_to :census_tract, index: true
      t.timestamps
    end
  end
end
