class AddPrecinctAliasReason < ActiveRecord::Migration[5.1]
  def change
    add_column(:precinct_aliases, :reason, :integer)
  end
end
