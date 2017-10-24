class AddYearReasonToCensusTract < ActiveRecord::Migration[5.1]
  def change
    add_column(:census_tracts, :reason, :integer)
    add_column(:census_tracts, :year, :string)
  end
end
