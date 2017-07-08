class Question < ActiveRecord::Base
  extend CommonToModel
  belongs_to :level
  belongs_to :category
  belongs_to :passage
  has_many :options
  has_many :papers_questions
  has_and_belongs_to_many :papers, through: :papers_questions
  accepts_nested_attributes_for :options
  def self.index_columns
    {
      'description' => 'Description',
      'category' => 'Category',
      'level' => 'Level'
    }
  end

  def self.index_actions
    {
      'new' => ['Add', 'new_question_path', :get],
      'edit' => ['Edit', 'edit_question_path', :get],
      'destroy' => ['Destroy', 'question_path', :delete]
    }
  end

  def set_used_in_free_plan
    self.used_in_free_plan = true
    self.save
  end

  def correct_option
    options.find_by(correct: true)
  end
end
