class Passage < ActiveRecord::Base
  extend CommonToModel
  has_many :questions
  accepts_nested_attributes_for :questions
  def self.index_columns
    {
      'title' => 'Title',
      'description' => 'Description',
    }
  end

  def self.index_actions
    {
      'new' => ['Add', 'new_passage_path', :get],
      'edit' => ['Edit', 'edit_passage_path', :get],
      'destroy' => ['Destroy', 'passage_path', :delete]
    }
  end
end
