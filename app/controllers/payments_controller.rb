class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:notification]
  skip_before_action :verify_authenticity_token, only: [:notification, :payu_callback]

  def init_subscribe
    respond_to do |format|
      if current_user.current_subscription.present?
        format.json{ render json: {status: "error", message: "Already subscribed to a plan"} }
      else
        format.json{ render json: init_with_payment_method }
      end
    end
  end

  def init_payment
    if current_user.current_subscription.present?
      render_ajax_error("Already subscribed to a plan")
    else
      @plan = Plan.find_by_id(plan_id)
      if @plan.present? && current_user.get_available_plans.include?(@plan)
        p_method = params[:payment_method] == "paypal" ? PaymentMethod::PAYPAL : PaymentMethod::PAYU
        @unpaid_plan_subscription, @invoice, @payment, @payment_method = current_user.get_or_add_pending_subscription(@plan, {payment_method: p_method, success_url: payment_success_callback_url, cancel_url: payment_cancel_callback_url})
        respond_to do |format|
          format.json{render json: {payment_id: @payment_method.unique_id}}
          format.js{ render "payments/payu_form" }
        end
      end
    end
  end

  def payment_success_callback
    unique_id = params[:paymentId]
    payer_id = params[:PayerID]
    proceed_with_unique_id(unique_id)
  end

  def payment_cancel_callback
    render text: "OK"
  end

  def payu_callback
    # ENV['PAYU_KEY'], ENV['PAYU_SALT']
    p "Payment Payu Success Params"
    p params
    notification = PayuIndia::Notification.new(request.query_string, options = {:key => ENV['PAYU_KEY'], :salt => ENV['PAYU_SALT'], :params => params})
    if notification.acknowledge && notification.complete?
      unique_id = notification.invoice
      proceed_with_unique_id(unique_id)
    end
  end

  def payu_cancel
    p "Payment Payu failure params"
    p params
    render text: "Payu payment is failed"
  end

  def paypal_callback_latest_old
    payment_id = params[:paymentId]
    token = params[:token]
    payer_id = params[:PayerID]
    @payment = Payment.where(paypal_payment_id: payment_id, payment_token: token).first
    respond_to do |format|
      if @payment.present?
        if ![Payment::STATUS[:paid], Payment::STATUS[:success]].include?(@payment.status)
          @payment.status = Payment::STATUS[:success]
          @payment.payer_id = payer_id
          @payment.save
          @payment.subscription.start_date = Date.today
          if @payment.subscription.plan.interval_count == 0
            @payment.subscription.end_date = 1000.days.from_now.to_date
          else
            @payment.subscription.end_date = @payment.subscription.plan.interval_count.send(@payment.subscription.plan.interval.downcase.pluralize).from_now.to_date
          end
          @payment.subscription.save
        end
        format.html {render "payments/thankyou" }
      else
        format.html {redirect_to root_url }
      end
    end
  end

  def payu_form
    plan = Plan.find_by_id(plan_id)
    respond_to do |format|
      if plan.present?
        @payment = user.subscriptions.joins(:payments).where(start_date: nil)
        format.js
      else
        flash[:alert] = "Invalid Request"
        redirect_js(root_url)
      end
    end
  end

  def paypal_callback_old
    respond_to do |format|
      amount = params[:amt]
      currency = params[:cc]
      encrypted_key = params[:cm]
      begin
        plain_text = AES.decrypt(encrypted_key, Gmatprep::Application.config.secret_for_encryption)
        proceed = true
      rescue OpenSSL::Cipher::CipherError => ex
        proceed = false
      end
      if proceed
        payment_id, amount, currency, gm_txn_id, created_at, plan_id = plain_text.split("$")
        if plan_id.to_i == params[:item_number].to_i
          plan_id = params[:item_number].to_i
          plan = Plan.find_by_id(plan_id)
          paypal_txn_id = params[:tx]
          status = params[:st]
          @payment = Payment.find_by_gm_txn_id(gm_txn_id)
          if @payment.present? && @payment.id == payment_id.to_i && @payment.amount == amount.to_f && @payment.created_at.to_i == created_at.to_i && @payment.currency == currency
            if ![Payment::STATUS[:paid], Payment::STATUS[:success]].include?(@payment.status) && @payment.amount == amount.to_f && status == "Completed"
              @payment.status = Payment::STATUS[:success]
              @payment.txn_id = paypal_txn_id
              @payment.save
              InfluxMonitor.push_to_influx("paid", {plan_name: plan.name})
            end
            format.html {render "payments/thankyou" }
          else
            format.html { render text: "Invalid Payment 1" }
          end
        else
          format.html { render text: "Invalid Payment 2" }
        end
      else
        format.html{ render text: "Invalid Payment 3" }
      end
    end
  end

  def paypal_cancel
    render text: "OK"
  end

  def notification
    respond_to do |format|
      encrypted_key = params[:custom]
      begin
        plain_text = AES.decrypt(encrypted_key, Gmatprep::Application.config.secret_for_encryption)
        proceed = true
      rescue OpenSSL::Cipher::CipherError => ex
        proceed = false
      end
      begin
        if proceed
          payment_id, amount, currency, gm_txn_id, created_at, plan_id = plain_text.split("$")
          payment = Payment.where(gm_txn_id: gm_txn_id).first
          if payment.present? && payment.id == payment_id.to_i && payment.amount == amount.to_f && payment.created_at.to_i == created_at.to_i && payment.currency == currency
            payment.payment_fee = params["payment_fee"]
            payment.txn_notify_data = params.except("controller", "action")
            payment.status = Payment::STATUS[:paid]
            payment.save
          end
        end
      rescue => ex
        Rails.logger.info "Payment Notification : #{ex.message}"
        Rails.logger.info params.except("controller", "action").inspect
        Rails.logger.info ex.backtrace.join("\n") if ex.respond_to?(:backtrace)
      end
      format.html { render text: "OK" }
    end
  end

  def thankyou
    respond_to do |format|
      format.html
    end
  end

  private

  def plan_id
    params[:plan_id]
  end

  def payment_method
    params[:payment_method]
  end

  def init_with_payment_method
    if ["paypal", "payu"].include?(payment_method)
      @plan = Plan.find_by_id(plan_id)
      if @plan.present? && current_user.get_available_plans.include?(@plan)
        # @plan_subscription = current_user.subscriptions.create(plan_id: plan_id) if (@plan_subscription = @plan.subscriptions.where(user_id: current_user.id, start_date: nil).joins(:pending_payment).first).blank?
        pending_plan_subscription = current_user.get_or_add_pending_subscription(@plan)
        if pending_plan_subscription.present?
          @payment = pending_plan_subscription.invoice.payments.pending.last
          if payment_method == "paypal"
            init_with_paypal
          else
            init_with_payu
          end
        else
          render_ajax_error("Invalid arguments")
        end
      else
        render_ajax_error("Invalid arguments")
      end
    else
      render_ajax_error("Invalid arguments")
    end
  end

  def init_with_paypal
    @payment_method = @payment.get_or_add_payment_method(PaymentMethod::PAYPAL)
    render_js("payments/payu_form")
  end

  def init_with_payu
    @payment_method = @payment.get_or_add_payment_method(PaymentMethod::PAYU)
    render_js("payments/payu_form")
  end

  def proceed_with_unique_id(unique_id)
    if (payment_method = PaymentMethod.find_by_unique_id(unique_id)).present?
      token = params[:token] || params[:item_number]
      if payment_method.match_token(token)
        @payment = payment_method.payment
        @payment.mark_success(payment_method)
        PaymentMailerWorker.perform_async(current_user.id, @payment.id)
        begin
          InfluxMonitor.push_to_influx("paid", {plan_name: @payment.invoice.subscription.plan.name})
        rescue => ex
          Rails.logger.info "exception occurred while adding paid data to influx"
        end
        format_redirect(payment_thankyou_url(payment_method.url_name, @payment.id))
      else
        render_ajax_error("Payment Failed")
      end
    else
      render_ajax_error("Payment Failed")
    end
  end
end
