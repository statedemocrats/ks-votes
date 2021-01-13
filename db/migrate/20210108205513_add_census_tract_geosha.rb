class AddCensusTractGeosha < ActiveRecord::Migration[6.0]
  def change
    add_column :census_tracts, :geosha, :string
    add_index :census_tracts, :geosha
  end
end
