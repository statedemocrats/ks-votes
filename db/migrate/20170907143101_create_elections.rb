class CreateElections < ActiveRecord::Migration[5.1]
  def change
    create_table :elections do |t|
      t.string :name
      t.date :date

      t.timestamps
    end
  end
end
