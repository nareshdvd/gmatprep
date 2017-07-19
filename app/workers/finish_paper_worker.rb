class FinishPaperWorker
  include Sidekiq::Worker
  def perform(paper_id)
    paper = Paper.find_by_id(paper_id)
    paper.complete_remaining_part
  end
end
