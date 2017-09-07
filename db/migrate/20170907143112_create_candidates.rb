class CreateCandidates < ActiveRecord::Migration[5.1]
  def change
    create_table :candidates do |t|
      t.string :name
      t.integer :party_id
      t.integer :office_id

      t.timestamps
    end
  end
end
