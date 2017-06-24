class AddCurrentTestIdToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :current_test_id, :integer
  end
end
