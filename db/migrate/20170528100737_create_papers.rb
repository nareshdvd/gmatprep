class CreatePapers < ActiveRecord::Migration
  def change
    create_table :papers do |t|
      t.datetime :start_time
      t.datetime :finish_time
      t.references :subscription, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
