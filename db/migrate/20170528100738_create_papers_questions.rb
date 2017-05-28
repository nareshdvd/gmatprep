class CreatePapersQuestions < ActiveRecord::Migration
  def change
    create_table :papers_questions do |t|
      t.references :paper, index: true, foreign_key: true
      t.references :question, index: true, foreign_key: true
      t.integer :question_number
      t.references :option, index: true, foreign_key: true
      t.datetime :start_time
      t.datetime :finish_time

      t.timestamps null: false
    end
  end
end
