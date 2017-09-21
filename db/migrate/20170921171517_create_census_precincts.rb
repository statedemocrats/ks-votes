class CreateCensusPrecincts < ActiveRecord::Migration[5.1]
  def change
    add_index(:counties, :fips, unique: true)

    create_table :census_precincts do |t|
      t.integer :county_id
      t.string :name
      t.string :code

      t.timestamps
    end

    add_index(:census_precincts, [:code, :county_id], unique: true)
    add_foreign_key(:census_precincts, :counties)
  end
end
