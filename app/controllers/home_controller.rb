class HomeController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:testing, :index]
  def index
    if current_user.blank?
      public_home
    else
      admin_dashboard if current_user.is_admin?
      candidate_dashboard if current_user.is_candidate?
    end
  end

  def testing
    respond_to do |format|
      format.html {render text: (Error.first.try(:error_message) || "404 Not Found")}
      format.json {render json: {"error" => "404 Not Found"}}
    end
  end

  def generate_payment
    if current_user.active_subscription.present?
      if current_user.active_subscription.plan.free_plan?
      else
      end
    end
  end

  def index_users
    @users = User.all
    respond_to do |format|
      if !current_user.is_admin?
        format.html {redirect_to root_path}
      else
        format.html {render "candidates/index"}
      end
    end
  end

  def destroy_papers
    respond_to do |format|
      if !current_user.is_admin?
        format.html {redirect_to root_path}
      else
        user = User.find_by_id(params[:candidate_id])
        user.subscriptions.each do |sbs|
          sbs.papers.destroy_all
        end
        format.html {redirect_to root_path}
      end
    end
  end

  private

  def public_home
    render "public/home"
  end
  def admin_dashboard
    render "admins/dashboard"
  end

  def candidate_dashboard
    @subscription = current_user.subscriptions.with_payments.with_plan.not_free.not_elapsed.not_exhausted.detect{|subscription| subscription.paid?(true) || subscription.success?(true)}
    @in_progress_paper = current_user.in_progress_paper
    render "candidates/dashboard"
  end
end
