class AddLowerIndexOnPrecinctName < ActiveRecord::Migration[5.1]
  def up
    execute("create index precincts_lower_name_idx on precincts(LOWER(name))")
    execute("create index precinct_aliases_lower_name_idx on precinct_aliases(LOWER(name))")
  end

  def down
    execute("drop index precincts_lower_name_idx")
    execute("drop index precinct_aliases_lower_name_idx")
  end
end
