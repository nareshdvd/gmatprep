class ChangeStatusTypeInPayment < ActiveRecord::Migration
  def up
    change_column :payments, :status, :integer, index: true
  end

  def down
    change_column :payments, :status, :string
  end
end
