class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:notification]
  skip_before_action :verify_authenticity_token, only: [:notification, :payment_cancel_callback, :payment_success_callback]

  def init_payment
    if current_user.current_subscription.present?
      render_ajax_error("Already subscribed to a plan")
    else
      @plan = Plan.find_by_id(plan_id)
      if @plan.present? && current_user.get_available_plans.include?(@plan)
        p_method = payment_method == "paypal" ? PaymentMethod::PAYPAL : PaymentMethod::PAYU
        @unpaid_plan_subscription, @invoice, @payment, @payment_method = current_user.get_or_add_pending_subscription(@plan, {payment_method: p_method, success_url: payment_success_callback_url, cancel_url: payment_cancel_callback_url})
        respond_to do |format|
          format.json{render json: {payment_id: @payment_method.unique_id}}
          format.js{ render "payments/payu_form" }
        end
      end
    end
  end

  def payment_success_callback
    if payment_method == "paypal"
      unique_id = params[:paymentId]
      payer_id = params[:PayerID]
      proceed_with_unique_id(unique_id)
    elsif payment_method == "payu"
      notification = PayuIndia::Notification.new(request.query_string, options = {:key => ENV['PAYU_KEY'], :salt => ENV['PAYU_SALT'], :params => params})
      if notification.acknowledge && notification.complete?
        unique_id = notification.invoice
        proceed_with_unique_id(unique_id)
      end
    else
      format_redirect(root_url)
    end
  end

  def payment_cancel_callback
    if payment_method == "paypal"
      unique_id = params[:paymentId]
      if (p_method = PaymentMethod.find_by_unique_id(unique_id)).present?
        token = params[:token]
        p_method.match_token(token)
        @payment = p_method.payment
        @payment.mark_failure(p_method, params)
        format_redirect(root_url)
      else
        format_redirect(root_url)
      end
    elsif payment_method == "payu"
      notification = PayuIndia::Notification.new(request.query_string, options = {:key => ENV['PAYU_KEY'], :salt => ENV['PAYU_SALT'], :params => params})
      if notification.acknowledge
        unique_id = notification.invoice
        if (p_method = PaymentMethod.find_by_unique_id(unique_id)).present?
          @payment = p_method.payment
          @payment.mark_failure(p_method, params)
          flash[:alert] = "Payment failed"
          format_redirect(root_url)
        else
          format_redirect(root_url)
        end
      else
        format_redirect(root_url)
      end
    else
      format_redirect(root_url)
    end
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
    @payment = current_user.subscriptions.joins({invoice: :successful_payment}).preload({invoice: :successful_payment}).where("payments.id=?", params[:payment_id]).last.invoice.successful_payment
    @payment_method = @payment.success_payment_method
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

  def proceed_with_unique_id(unique_id)
    if (p_method = PaymentMethod.find_by_unique_id(unique_id)).present?
      token = params[:token] || unique_id
      if p_method.match_token(token)
        @payment = p_method.payment
        @payment.mark_success(p_method, params)
        PaymentMailerWorker.perform_async(current_user.id, @payment.id)
        begin
          InfluxMonitor.push_to_influx("paid", {plan_name: @payment.invoice.subscription.plan.name})
        rescue => ex
          Rails.logger.info "exception occurred while adding paid data to influx"
        end
        format_redirect(payment_thankyou_url(p_method.url_name, @payment.id))
      else
        render_ajax_error("Payment Failed")
      end
    else
      render_ajax_error("Payment Failed")
    end
  end
end
