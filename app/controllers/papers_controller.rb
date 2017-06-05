class PapersController < ApplicationController
  load_and_authorize_resource
  def new
    if (in_progress_paper = current_user.in_progress_paper).blank?
      if (active_subscription = current_user.active_subscription).present?
        if active_subscription.elapsed?
          format.html { redirect_to root_path, notice: "Your subscription has been finished" }
        elsif active_subscription.exhausted?
          format.html { redirect_to root_path, notice: "You have finished all the tests in your subscription" }
        else
          in_progress_paper = active_subscription.papers.create(start_time: Time.now)
        end
      else
        format.html { redirect_to root_path, notice: "You don't have any active subscriptions" }
      end
    end
    if in_progress_paper.present?
      if (question_count = in_progress_paper.papers_questions.count) == 0
        question = in_progress_paper.add_question(true)
      elsif (last_question = in_progress_paper.papers_questions.last).unanswered?
        question = last_question
      else
        question = in_progress_paper.add_question
      end
      format.html {redirect_to papers_question_path(question.question_number)}
    end
  end

  def question
    question_number = params[:question_number].to_i
    if question_number > 41 || question_number < 1
      format.html { redirect_to root_path, notice: "Question Not found" }
    elsif (in_progress_paper = current_user.in_progress_paper).blank?
      format.html { redirect_to root_path, notice: "Test Finished" }
    elsif (last_question = in_progress_paper.papers_questions.last).unanswered?
      @paper_question = last_question
      format.html
    else
      format.html {redirect_to papers_question_path(paper.add_question().question_number)}
    end
  end

  def answer_question
    question_number = params[:question_number].to_i
    if question_number > 41 || question_number < 1
      format.html { redirect_to root_path, notice: "Question Not found" }
    elsif (in_progress_paper = current_user.in_progress_paper).blank?
      format.html { redirect_to root_path, notice: "Test not found" }
    elsif (last_question = in_progress_paper.papers_questions.last).unanswered?
      @paper_question = last_question
      @paper_question.update_attributes(answer_params)
      format.html
    elsif in_progress_paper.papers_questions.last.question_number == 41
      format.html {redirect_to root_path, notice: "Paper Finished"}
    else
      format.html {redirect_to papers_question_path(paper.add_question().question_number)}
    end
    # question_number = params[:question_number].to_i
    # respond_to do |format|
    #   if (active_subscription = current_user.active_subscription).present?
    #     if (paper = active_subscription.in_progress_paper).present?
    #       @paper_question = paper.papers_questions.where(question_number: question_number).first
    #       @paper_question.update_attributes(answer_params)
    #       if (question_number + 1) == Paper::QUESTION_COUNT
    #         if (@paper_question = paper.papers_questions.where(question_number: (question_number + 1)).first).blank?
    #           question_number = paper.add_question().question_number
    #           format.html {redirect_to papers_question_path(question_number)}
    #         else
    #           question_number = @paper_question.question_number
    #           format.html {redirect_to papers_question_path(question_number)}
    #         end
    #       elsif question_number == Paper::QUESTION_COUNT
    #         format.html {redirect_to root_path, notice: "Paper Finished"}
    #       else
    #         question_number = paper.add_question().question_number
    #         format.html {redirect_to papers_question_path(question_number)}
    #       end
    #     else
    #       format.html {redirect_to root_path, notice: "Paper Finished"}
    #     end
    #   else
    #     format.html { redirect_to root_path, notice: "You don't have any active subscriptions" }
    #   end
    # end
  end

  private

  def answer_params
    params.require(:papers_question).permit(:option_id)
  end
end
