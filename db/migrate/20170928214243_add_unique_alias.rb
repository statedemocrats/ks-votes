class AddUniqueAlias < ActiveRecord::Migration[5.1]
  def change
    add_index(:precinct_aliases, [:name, :precinct_id], unique: true)
  end
end
