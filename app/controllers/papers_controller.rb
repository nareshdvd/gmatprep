class PapersController < ApplicationController
  load_and_authorize_resource
  def new
    if (in_progress_paper = current_user.in_progress_paper).blank?
      if (active_subscription = current_user.active_subscription).present?
        if active_subscription.elapsed?
          redirect_to root_path, notice: "Your subscription has been finished"
        elsif active_subscription.exhausted?
          redirect_to root_path, notice: "You have finished all the tests in your subscription"
        else
          in_progress_paper = active_subscription.papers.create(start_time: Time.now)
        end
      else
        redirect_to root_path, notice: "You don't have any active subscriptions"
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
      redirect_to papers_question_path(question.question_number)
    end
  end

  def question
    respond_to do |format|
      question_number = params[:question_number].to_i
      if question_number > Paper::QUESTION_COUNT || question_number < 1
        redirect_to root_path, notice: "Question Not found"
      elsif (in_progress_paper = current_user.in_progress_paper).blank?
        redirect_to root_path, notice: "Test Finished"
      elsif (last_question = in_progress_paper.papers_questions.last).unanswered?
        if last_question.question_number != question_number
          redirect_to papers_question_path(last_question.question_number)
        else
          @paper_question = last_question
          format.html
        end
      else
        redirect_to papers_question_path(in_progress_paper.add_question().question_number)
      end
    end
  end

  def answer_question
    question_number = params[:question_number].to_i
    if question_number > Paper::QUESTION_COUNT || question_number < 1
      redirect_to root_path, notice: "Question Not found"
    elsif (in_progress_paper = current_user.in_progress_paper).blank?
      redirect_to root_path, notice: "Test not found"
    elsif (last_question = in_progress_paper.papers_questions.last).unanswered?
      @paper_question = last_question
      @paper_question.update_attributes(answer_params)
      if @paper_question.question_number < Paper::QUESTION_COUNT
        redirect_to papers_question_path(in_progress_paper.add_question().question_number)
      else
        redirect_to root_path, notice: "Paper Finished"
      end
    elsif in_progress_paper.papers_questions.last.question_number == Paper::QUESTION_COUNT
      redirect_to root_path, notice: "Paper Finished"
    else
      redirect_to papers_question_path(in_progress_paper.add_question().question_number)
    end
  end

  private

  def answer_params
    params.require(:papers_question).permit(:option_id)
  end
end
