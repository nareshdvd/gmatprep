class AddFinishedTestCountToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :finished_test_count, :integer, default: 0
  end
end
