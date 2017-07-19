class PapersController < ApplicationController
  before_action :find_paper, only: [:test_finish, :finish_test, :show_score, :question, :answer_question]
  before_action :find_subscription, only: [:instructions, :new]
  before_action :redirect_if_in_progress, only: [:instructions, :new]
  before_action :redirect_if_not_in_progress, only: [:question, :answer_question]
  def test_finish
    respond_to do |format|
      if @paper.finish_time.blank?
        @paper.complete_remaining_part
        @paper.update_attributes({finish_time: Time.now})
      end
      if @paper.paper_finish_displayed
        format.html{ redirect_to paper_score_path(@paper) }
      else
        @paper.update_attribute(:paper_finish_displayed, true)
        format.html{ render "candidates/paper_finish" }
      end
    end
  end

  def finish_test
    respond_to do |format|
      sleep(5)
      format.html{ redirect_to paper_score_path(@paper) }
    end
  end

  def show_score
    respond_to do |format|
      format.html{ render "candidates/score" }
    end
  end

  def instructions
    step_number = params[:step_number]
    respond_to do |format|
      if @subscription.plan.free_plan? || @subscription.paid?
        if @subscription.elapsed?
          format.html{ redirect_to root_path, alert: "Your subscription has elapsed" }
        elsif @subscription.exhausted?
          format.html{ redirect_to root_path, alert: "Your subscription has finished" }
        else
          if ['1', '2'].include?(step_number)
            format.html{ render "candidates/paper_start_step_#{step_number}" }
          else
            format.html{ redirect_to paper_instructions_url(@subscription.id, 1)}
          end
        end
      else
        format.html{ redirect_to root_path, alert: "Subscription not available" }
      end
    end
  end

  def new
    respond_to do |format|
      if (paper = in_progress_paper).present?
        if paper.subscription.id == subscription_id
          if (question = paper.papers_questions.last).present?
            if question.unanswered?
              format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
            elsif question.question_number == 41
              format.html{ redirect_to paper_finish_path(paper.id) }
            else
              question = paper.add_question
              format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
            end
          else
            question = paper.add_question(true)
            format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
          end
        else
          format.html{ redirect_to root_path, alert: "You already have an test in progress" }
        end
      else
        if @subscription.plan.free_plan? || @subscription.paid?
          if @subscription.elapsed?
            format.html{ redirect_to root_path, alert: "Your subscription has elapsed" }
          elsif @subscription.exhausted?
            format.html{ redirect_to root_path, alert: "Your subscription has finished" }
          else
            paper = @subscription.papers.create(start_time: Time.now)
            FinishPaperWorker.perform_in(Paper::MINUTES.minutes + 2.seconds, paper.id)
            InfluxMonitor.push_to_influx("started_test", {"plan" => @subscription.plan.name})
            question = paper.add_question(true)
            format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
          end
        else
          format.html{ redirect_to root_path, alert: "Subscription not available" }
        end
      end
    end
  end

  def question
    question_number = params[:question_number].to_i
    respond_to do |format|
      if @paper.id == in_progress_paper.id
        last_question = @paper.papers_questions.last
        if last_question.blank?
          last_question = @paper.add_question(true)
        end
        if last_question.unanswered?
          if last_question.question_number == question_number
            @paper_question = last_question
            format.html
          else
            format.html{ redirect_to papers_question_path(paper_id, last_question.question_number) }
          end
        elsif last_question.question_number == 41
          format.html{ redirect_to paper_finish_path(@paper.id) }
        else
          @paper_question = @paper.add_question
          format.html
        end
      else
        format.html{ redirect_to root_path, alert: "Paper not available" }
      end
    end
  end

  def answer_question
    question_number = params[:question_number].to_i
    respond_to do |format|
      if @paper.id == in_progress_paper.id
        last_question = @paper.papers_questions.last
        if last_question.question_number == question_number
          if last_question.unanswered?
            last_question.update_attributes(answer_params)
            last_question.finish_time = Time.now
            last_question.save
          end
          if last_question.question_number == 41
            format.html{ redirect_to paper_finish_path(@paper.id) }
          else
            next_question = @paper.add_question
            format.html {redirect_to papers_question_path(@paper.id, next_question.question_number)}
          end
        else
          format.html{ redirect_to root_path, alert: "Incorrect question number" }
        end
      else
        format.html{ redirect_to root_path, alert: "Paper not available" }
      end
    end
  end

  
  private
  
  def answer_params
    params.require(:papers_question).permit(:option_id)
  end

  def find_paper
    @paper = Paper.where(id: params[:paper_id]).first
    if @paper.blank? || @paper.subscription.user_id != current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  def find_subscription
    @subscription = current_user.subscriptions.where(id: subscription_id).first
    raise ActiveRecord::RecordNotFound if @subscription.blank?
  end

  def redirect_if_in_progress
    redirect_to root_path, alert: "Paper already in progress" if in_progress_paper.present?
  end

  def redirect_if_not_in_progress
    redirect_to root_path, alert: "Paper not found" if in_progress_paper.blank?
  end

  def in_progress_paper
    @in_progress_paper ||= current_user.in_progress_paper
  end

  def paper_id
    params[:paper_id].to_i
  end

  def subscription_id
    params[:subscription_id].to_i
  end
end
