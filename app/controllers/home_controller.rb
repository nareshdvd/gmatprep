class HomeController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:index]
  def index
    monitor = InfluxMonitor.should_monitor?(cookies, :asynchronous_visitor_monitoring)
    if current_user.blank?
      InfluxMonitor.push_to_influx("visited", {user: "anonymous"}) if monitor
      public_home
    else
      if user_is_admin?
        InfluxMonitor.push_to_influx("visited", {user: "admin"}) if monitor
        admin_dashboard
      else
        InfluxMonitor.push_to_influx("visited", {user: "candidate"}) if monitor
        candidate_dashboard if user_is_candidate?
      end
    end
  end

  def index_users
    @users = User.all
    respond_to do |format|
      if !user_is_admin?
        format.html {redirect_to root_path}
      else
        format.html {render "candidates/index"}
      end
    end
  end

  def destroy_papers
    if !user_is_admin?
      flash[:notice] = "Not found"
      redirect_js(root_path)
    else
      user = User.find_by_id(params[:candidate_id])
      user.subscriptions.each do |sbs|
        sbs.papers.destroy_all
      end
      flash[:notice] = "all papers are reset for #{user.email}"
      redirect_js(index_users_path)
    end
  end

  private

  def public_home
    render "public/home"
  end
  def admin_dashboard
    render "admins/summary"
  end

  def candidate_dashboard
    InfluxMonitor.push_to_influx("visited", {user: current_user.roles.first.name}) if InfluxMonitor.should_monitor?(cookies, :candidate_visitor_monitoring)
    redirect_to my_home_path
  end
end
