class AddPrecinctCensusTractId < ActiveRecord::Migration[5.1]
  def change
    add_column(:precincts, :census_tract_id, :integer, index: true)
    add_foreign_key(:precincts, :census_tracts)
  end
end
