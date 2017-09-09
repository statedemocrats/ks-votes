class AddResultChecksum < ActiveRecord::Migration[5.1]
  def change
    add_column(:results, :checksum, :string)
  end
end
