class ChangePrecinctIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index(:precincts, [:name, :county_id])
    add_index(:precincts, [:name, :county_id, :census_tract_id], unique: true)
  end
end
