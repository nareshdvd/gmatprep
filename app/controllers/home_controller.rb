class HomeController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:testing, :index]
  def index
    monitor = InfluxMonitor.should_monitor?(cookies, :asynchronous_visitor_monitoring)
    if current_user.blank?
      InfluxMonitor.push_to_influx("visited", {user: "anonymous"}) if monitor
      public_home
    else
      if current_user.is_admin?
        InfluxMonitor.push_to_influx("visited", {user: "admin"}) if monitor
        admin_dashboard
      else
        InfluxMonitor.push_to_influx("visited", {user: "candidate"}) if monitor
        candidate_dashboard if current_user.is_candidate?
      end
    end
  end

  def testing
    respond_to do |format|
      format.html {render text: (Error.first.try(:error_message) || "404 Not Found")}
      format.json {render json: {"error" => "404 Not Found"}}
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
    InfluxMonitor.push_to_influx("visited", {user: current_user.roles.first.name}) if InfluxMonitor.should_monitor?(cookies, :candidate_visitor_monitoring)
    subscriptions = current_user.subscriptions.paid_usable.with_payments.with_plan.not_free.not_elapsed.not_exhausted
    Rails.logger.info "SUBSCRIPTIONS for User user_id: #{current_user.id}"
    Rails.logger.info subscriptions.collect(&:id).join("------")
    Rails.logger.info "--------------------------------------------------"
    @subscription = subscriptions.detect{|subscription| subscription.paid?(true) || subscription.success?(true)}
    @in_progress_paper = current_user.in_progress_paper
    render "candidates/dashboard"
  end
end
