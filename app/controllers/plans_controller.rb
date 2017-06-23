class PlansController < ApplicationController
  def init_subscribe
    plan_id = params[:id].to_i
    already_subscribed = false
    user = current_user
    (subscriptions = user.subscriptions.with_payments.with_plan.not_free.not_elapsed.not_exhausted).each do |subscription|
      if subscription.paid?(true)
        # user is already subscribed to some paid plan and cannot subscribe to another plan right now
        already_subscribed = true
        break;
      end
    end

    respond_to do |format|
      if !already_subscribed
        @plan = Plan.find_by_id(plan_id)
        if (pending_subscription = subscriptions.select{|subscription| subscription.plan_id == plan_id && subscription.pending?(true)}.first).present?
          @payment = pending_subscription.payments.detect{|payment| payment.status == Payment::STATUS[:pending]}
        elsif (initiated_subscription = subscriptions.select{|subscription| subscription.plan_id == plan_id && subscription.initiated?(true)}.first).present?
          initiated_payment = initiated_subscription.payments.detect{|payment| payment.status == Payment::STATUS[:initiated]}
          initiated_payment.update_attribute(:status, Payment::STATUS[:canceled])
          @payment = initiated_subscription.create_payment
        else
          InfluxMonitor.push_to_influx("clicked_on_subscribe", {plan_name: @plan.name})
          subscription = user.subscriptions.create(plan_id: plan_id)
          @payment = subscription.payments.first
          @payment.create_paypal_payment(paypal_success_url, paypal_cancel_url)
        end
        format.js { render "plans/init_subscribe" }
        format.json {render json: {payment_id: @payment.paypal_payment_id}}
      else
        @redirect_to = root_url
        flash[:notice] = "Already subscribed to a plan"
        format.js { render "shared/redirect" }
      end
    end
  end
end
