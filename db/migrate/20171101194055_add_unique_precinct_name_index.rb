class AddUniquePrecinctNameIndex < ActiveRecord::Migration[5.1]
  def change
    add_index(:precincts, [:name, :county_id], unique: true)
  end
end
