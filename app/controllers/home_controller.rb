class HomeController < ApplicationController
  def index
    admin_dashboard if current_user.is_admin?
    candidate_dashboard if current_user.is_candidate?
  end

  private
  def admin_dashboard
    render "admins/dashboard"
  end

  def candidate_dashboard
    render "candidates/dashboard"
  end
end
