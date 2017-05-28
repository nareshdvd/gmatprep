class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name
      t.float :amount
      t.string :currency
      t.integer :paper_count
      t.string :interval
      t.integer :interval_count

      t.timestamps null: false
    end
  end
end
