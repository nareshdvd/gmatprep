class ReportsController < ApplicationController
  def index
    paper_id = params[:paper_id]
    @paper = Paper.find_by(id: paper_id)
    respond_to do |format|
      if @paper.papers_questions.count != 41 || @paper.papers_questions.last.unanswered?
        format.html{redirect_to root_path, notice: "This paper hasn't been finished, so report generation is not possible"}
      elsif @paper.subscription.user_id != current_user.id
        format.html{redirect_to "404NotFound"}
      else
        format.html
      end
    end
  end

  def charts
    paper_id = params[:paper_id]
    @paper = Paper.find_by(id: paper_id)
    respond_to do |format|
      if @paper.papers_questions.count != 41 || @paper.papers_questions.last.unanswered?
        format.html{redirect_to root_path, notice: "This paper hasn't been finished, so report generation is not possible"}
      elsif @paper.blank?
        format.html{redirect_to root_path, notice: "Report Not Found"}
      else
        if @paper.subscription.user_id != current_user.id
          format.html{redirect_to root_path, notice: "Report Not Found"}
        else
          format.html
        end
      end
    end
  end
end