class ModifyCensusTractIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index(:census_tracts, [:vtd_code, :county_id])
    add_index(:census_tracts, [:vtd_code, :county_id, :year], unique: true)
  end
end
