class AddResultReason < ActiveRecord::Migration[5.1]
  def change
    add_column(:results, :reason, :integer)
  end
end
