class PlansController < ApplicationController
  def init_subscribe
    respond_to do |format|
      if (subscriptions = current_user.subscriptions.with_plan.not_free.not_elapsed).blank?
        @plan = Plan.find_by_id(params[:id])
        subscription = current_user.subscriptions.create(plan_id: plan.id, is_active: false)
        @payment = subscription.payments.create(status: Payment::STATUS[:pending], amount: plan.amount, currency: plan.currency, gm_txn_id: SecureRandom.hex(8))
        format.js {render "plans/init_subscribe"}
      else
        subscription = subscriptions.with_payments.where("payments.status = ?", Payment::STATUS[:pending]).first
        if subscription.plan_id == params[:id].to_i
          @payment = subscription.payments.where(status: Payment::STATUS[:pending]).first
          @plan = subscription.plan
          format.js {render "plans/init_subscribe"}
        else
          @message = "Cannot subscribe to the plan"
        end
      end
    end
  end
end