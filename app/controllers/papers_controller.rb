class PapersController < ApplicationController
  load_and_authorize_resource
  skip_before_action :authenticate_user!, only: [:test]
  def test

  end

  def new
    subscription_id = params[:subscription_id].to_i
    respond_to do |format|
      if (paper = current_user.in_progress_paper).present?
        if paper.subscription.id == subscription_id
          if (question = paper.papers_questions.last).present?
            if question.unanswered?
              format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
            elsif question.question_number == 41
              if paper.finish_time.blank?
                paper.update_attributes({finish_time: Time.now})
                paper.subscription.update_attributes({current_test_id: nil, finished_test_count: paper.subscription.finished_test_count + 1})
              end
            else
              question = paper.add_question
              format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
            end
          else
            question = paper.add_question(true)
            format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
          end
        else
          format.html{ redirect_to root_path, notice: "You already have an test in progress" }
        end
      else
        if (subscription = Subscription.find_by_id(subscription_id)).present?
          if subscription.plan.free_plan? || subscription.paid? || subscription.success?
            if subscription.elapsed?
              format.html{ redirect_to root_path, notice: "Your subscription has elapsed" }
            elsif subscription.exhausted?
              format.html{ redirect_to root_path, notice: "Your subscription has finished" }
            else
              paper = subscription.papers.create(start_time: Time.now)
              subscription.current_test_id = paper.id
              subscription.started_test_count = subscription.started_test_count + 1
              subscription.save
              InfluxMonitor.push_to_influx("started_test", {"plan" => subscription.plan.name})
              question = paper.add_question(true)
              format.html{ redirect_to papers_question_path(paper.id, question.question_number) }
            end
          else
            format.html{ redirect_to root_path, notice: "Subscription not available" }
          end
        else
          format.html{ redirect_to root_path, notice: "Subscription not available" }
        end
      end
    end
  end

  def question
    paper_id = params[:paper_id].to_i
    question_number = params[:question_number].to_i
    respond_to do |format|
      if (@paper = current_user.in_progress_paper).present? && @paper.id == paper_id
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
          if @paper.finish_time.blank?
            @paper.update_attributes({finish_time: Time.now})
            @paper.subscription.update_attributes({current_test_id: nil, finished_test_count: @paper.subscription.finished_test_count + 1})
          end
          format.html{ redirect_to root_path, notice: "Paper finished" }
        else
          @paper_question = @paper.add_question
          format.html
        end
      else
        format.html{ redirect_to root_path, notice: "Paper not found" }
      end
    end
  end

  def answer_question
    paper_id = params[:paper_id].to_i
    question_number = params[:question_number].to_i
    respond_to do |format|
      if (paper = current_user.in_progress_paper).present? && paper.id == paper_id
        last_question = paper.papers_questions.last
        if last_question.question_number == question_number
          if last_question.unanswered?
            last_question.update_attributes(answer_params)
          end
          if last_question.question_number == 41
            if paper.finish_time.blank?
              paper.update_attributes({finish_time: Time.now})
              paper.subscription.update_attributes({current_test_id: nil, finished_test_count: paper.subscription.finished_test_count + 1})
            end
            format.html{ redirect_to root_path, notice: "Paper finished" }
          else
            next_question = paper.add_question
            format.html {redirect_to papers_question_path(paper.id, next_question.question_number)}
          end
        else
          format.html{ redirect_to root_path, notice: "Incorrect question number" }
        end
      else
        format.html{ redirect_to root_path, notice: "Paper not found" }
      end
    end
  end

  
  private

  def answer_params
    params.require(:papers_question).permit(:option_id)
  end
end
