class Option < ActiveRecord::Base
  extend CommonToModel
  belongs_to :question
  def is_correct?
    correct
  end
end
