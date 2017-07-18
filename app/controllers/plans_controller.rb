class PlansController < ApplicationController
  def init_subscribe
    plan_id = params[:id].to_i
    user = current_user
    respond_to do |format|
      if current_user.current_subscription.present?
        @redirect_to = root_url
        flash[:notice] = "Already subscribed to a plan"
        format.js { render "shared/redirect" }
      else
        @plan = Plan.find_by_id(plan_id)
        plan_subscription = @plan.subscriptions.where(user_id: user.id, start_date: nil).joins(:pending_payment)
        if current_user.get_available_plans.include?(@plan)
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
        else
          format.json{render json: {error: "Plan not available"}}
        end
      end
    end
  end
end
