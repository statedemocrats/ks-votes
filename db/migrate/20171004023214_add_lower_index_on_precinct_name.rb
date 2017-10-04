class AddLowerIndexOnPrecinctName < ActiveRecord::Migration[5.1]
  def up
    execute("create index precincts_lower_name_idx on precincts(LOWER(name))")
  end

  def down
    execute("drop index precincts_lower_name_idx")
  end
end
