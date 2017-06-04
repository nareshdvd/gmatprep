class AddEndDateToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :end_date, :date
  end
end
