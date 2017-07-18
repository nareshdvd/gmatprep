class CandidatesController < ApplicationController
  before_action :is_candidate?
  before_action :in_progress_paper?, only: [:start_test, :buy_new]
  def home
  end

  def start_test
    test_action = params[:test_action]
    paid_info = params[:paid_info]
    respond_to do |format|
      if current_user.current_test.present?
        format.html{ redirect_to papers_question_path(current_user.current_test, current_user.current_test.papers_questions.last.id) }
      else
        if paid_info == "free"
          if current_user.free_subscription.exhausted?
            format.html{ redirect_to root_path, notice: "You already have finished your free test" }
          else
            format.html{ redirect_to paper_instructions_path(current_user.free_subscription.id, 1) }
          end
        elsif paid_info == "paid"
          if (current_subscription = current_user.current_subscription).present?
            format.html{ redirect_to paper_instructions_path(current_subscription.id, 1) }
          else
            format.html{ redirect_to root_path, notice: "You dont have any paid subscriptions" }
          end
        else
          format.html{ redirect_to root_path, notice: "Oops! Page says, I don't know what you are looking for" }
        end
      end
    end
  end

  def buy_new
    respond_to do |format|
      if current_user.current_subscription.present?
        format.html{ redirect_to root_path, notice: "You already have subscribed"}
      else
        @plans = current_user.get_available_plans
        format.html
      end
    end
  end

  def finished_tests
    @finished_tests = current_user.completed_tests
  end

  def remaining_tests
    
  end
end