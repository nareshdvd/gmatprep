class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :plan, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.boolean :is_active, indexed: true
      t.timestamps null: false
    end
  end
end
