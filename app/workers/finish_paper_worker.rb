class FinishPaperWorker
  include Sidekiq::Worker
  def perform(paper_id)
    paper = Paper.find_by_id(paper_id)
    if paper.finish_time.blank?
      finished_question_count = paper.finished_questions.count
      while finished_question_count < Paper::QUESTION_COUNT
        if (last_question = paper.papers_questions.last).answered?
          last_question = paper.add_question()
        end
        last_question.update_attributes({
          option_id: (last_question.question.options.where("correct != ?", true).first.id),
          finish_time: Time.now
        })
        finished_question_count += 1
      end
      paper.update_attribute(:finish_time, Time.now)
    end
  end
end
