class AddQuestionScoreToLevels < ActiveRecord::Migration
  def change
    add_column :levels, :question_score, :float
  end
end
