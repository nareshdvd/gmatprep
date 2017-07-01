class PlansController < ApplicationController
  def init_subscribe
    plan_id = params[:id].to_i
    user = current_user
    paid_usable_subscriptions = user.usable_subscriptions
    respond_to do |format|
      if paid_usable_subscriptions.present?
        @redirect_to = root_url
        flash[:notice] = "Already subscribed to a plan"
        format.js { render "shared/redirect" }
      else
        @plan = Plan.find_by_id(plan_id)
        plan_subscription = @plan.subscriptions.where(user_id: user.id).joins(:payments).preload(:payments).where("payments.status NOT IN (?)", [Payment::STATUS[:success], Payment::STATUS[:paid]]).first
        if plan_subscription.blank?
          InfluxMonitor.push_to_influx("clicked_on_subscribe", {plan_name: @plan.name})
          plan_subscription = user.subscriptions.create(plan_id: plan_id)
        end
        @payment = plan_subscription.payments.detect{|payment| [Payment::STATUS[:pending], Payment::STATUS[:initiated]].include?(payment.status)}
        if @payment.blank?
          @payment = plan_subscription.create_payment
        end
        if @payment.paypal_payment_id.blank? || @payment.payment_token.blank?
          @payment.create_paypal_payment(paypal_success_url, paypal_cancel_url)
        end
        format.json {render json: {payment_id: @payment.paypal_payment_id}}
      end
    end
  end

  def init_subscribe_old
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
