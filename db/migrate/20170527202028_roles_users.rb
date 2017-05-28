class RolesUsers < ActiveRecord::Migration
  def change
    create_table :roles_users do |t|
      t.references :role, indexed: true, foreign_key: true
      t.references :user, indexed: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
