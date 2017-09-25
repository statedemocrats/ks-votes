class AddCensusPrecinctFk < ActiveRecord::Migration[5.1]
  def change
    add_column(:precincts, :census_precinct_id, :integer)
    add_foreign_key(:precincts, :census_precincts)
  end
end
