class PapersController < ApplicationController
  load_and_authorize_resource
  def new
    respond_to do |format|
      if (active_subscription = current_user.active_subscription).present?
        if (paper = active_subscription.in_progress_paper).blank?
          if active_subscription.remaining_paper_count != 0
            paper = active_subscription.papers.create(start_time: Time.now)
            paper.add_question(true)
          else
            format.html { redirect_to root_path, notice: "You has finished all tests in your subscription" }
          end
        end
      else
        format.html { redirect_to root_path, notice: "You don't have any active subscriptions" }
      end
      if paper.present?
        if paper.last_question_unanswered?
          question_number = paper.papers_questions.last.question_number
          format.html {redirect_to papers_question_path(question_number)}
        elsif paper.papers_questions.count == Paper::QUESTION_COUNT
          format.html {redirect_to root_path, notice: "Paper Finished"}
        else
          question_number = paper.add_question().question_number
          format.html {redirect_to papers_question_path(question_number)}
        end
      else
        format.html {redirect_to root_path, notice: "Cannot create new test this time"}
      end
    end
  end

  def question
    question_number = params[:question_number].to_i
    respond_to do |format|
      if (active_subscription = current_user.active_subscription).present?
        if (paper = active_subscription.in_progress_paper).blank? || paper.last_question_unanswered?
          @paper_question = paper.papers_questions.where(question_number: question_number).first
          format.html
        else
          question_number = paper.add_question().question_number
          format.html {redirect_to papers_question_path(question_number)}
        end
      else
        format.html { redirect_to root_path, notice: "You don't have any active subscriptions" }
      end
    end
  end

  def answer_question
    question_number = params[:question_number].to_i
    respond_to do |format|
      if (active_subscription = current_user.active_subscription).present?
        if (paper = active_subscription.in_progress_paper).present?
          @paper_question = paper.papers_questions.where(question_number: question_number).first
          @paper_question.update_attributes(answer_params)
          if (question_number + 1) == Paper::QUESTION_COUNT
            if (@paper_question = paper.papers_questions.where(question_number: (question_number + 1)).first).blank?
              question_number = paper.add_question().question_number
              format.html {redirect_to papers_question_path(question_number)}
            else
              question_number = @paper_question.question_number
              format.html {redirect_to papers_question_path(question_number)}
            end
          elsif question_number == Paper::QUESTION_COUNT
            format.html {redirect_to root_path, notice: "Paper Finished"}
          else
            question_number = paper.add_question().question_number
            format.html {redirect_to papers_question_path(question_number)}
          end
        else
          format.html {redirect_to root_path, notice: "Paper Finished"}
        end
      else
        format.html { redirect_to root_path, notice: "You don't have any active subscriptions" }
      end
    end
  end

  private

  def answer_params
    params.require(:papers_question).permit(:option_id)
  end
end
