class AddIsActiveToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :is_active, :boolean
    add_index :plans, :is_active
  end
end
