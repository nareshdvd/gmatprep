class AddStartedTestCountToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :started_test_count, :integer, default: 0
  end
end
