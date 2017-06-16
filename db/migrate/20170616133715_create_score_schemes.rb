class CreateScoreSchemes < ActiveRecord::Migration
  def change
    create_table :score_schemes do |t|
      t.integer :deduction
      t.integer :score

      t.timestamps null: false
    end
  end
end
