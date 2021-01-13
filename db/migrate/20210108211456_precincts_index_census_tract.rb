class PrecinctsIndexCensusTract < ActiveRecord::Migration[6.0]
  def change
    remove_index :precincts, [:name, :county_id]
  end
end
