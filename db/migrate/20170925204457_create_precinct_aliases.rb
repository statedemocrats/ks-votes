class CreatePrecinctAliases < ActiveRecord::Migration[5.1]
  def change
    create_table :precinct_aliases do |t|
      t.integer :census_precinct_id
      t.string  :name
      t.timestamps
    end
    add_index(:precinct_aliases, [:census_precinct_id, :name], unique: true)
    add_foreign_key(:precinct_aliases, :census_precincts)
  end
end
