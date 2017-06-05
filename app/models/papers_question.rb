class PapersQuestion < ActiveRecord::Base
  belongs_to :paper
  belongs_to :question
  belongs_to :option

  def passage_question?
    question.passage_id.present?
  end

  def unanswered?
    !answered?
  end

  def answered?
    self.option_id.present?
  end
end
