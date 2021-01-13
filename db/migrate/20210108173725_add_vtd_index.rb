class AddVtdIndex < ActiveRecord::Migration[6.0]
  def change
    add_index(:census_tracts, :vtd_code)
  end
end
