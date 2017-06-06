class HomeController < ApplicationController
  def index
    admin_dashboard if current_user.is_admin?
    candidate_dashboard if current_user.is_candidate?
  end

  def generate_payment
    if current_user.active_subscription.present?
      if current_user.active_subscription.plan.free_plan?
      else
      end
    end
    # plan_id = params[:plan_id]
    # plan = Plan.find_by_id(plan_id)
    # if (subscription = current_user.subscriptions.where(plan_id: plan_id).first).blank?
    #   subscription = current_user.subscriptions.build(plan_id: plan_id, is_active: false)
    #   subscription.save
    # end
    # if subscription.time_elapsed? || subscription.all_tests_finished?
    # elsif subscription.already_paid?
    # elsif subscription.awaiting_payment_recipt?
    # elsif subscription.payment_already_generated?
    # else
    # end
    # respond_to do |format|
    #   format.json {render json: {gm_txn_id: payment.gm_txn_id}}
    # end
  end

  private
  def admin_dashboard
    render "admins/dashboard"
  end

  def candidate_dashboard
    @subscription = current_user.subscriptions.with_payments.with_plan.not_free.not_elapsed.not_exhausted.detect{|subscription| subscription.paid?(true) || subscription.success?(true)}
    @in_progress_paper = current_user.in_progress_paper
    render "candidates/dashboard"
  end
end
