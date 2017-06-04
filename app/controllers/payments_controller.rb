class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:notification]
  skip_before_action :verify_authenticity_token, only: [:notification]

  def init_payment
    payment_id = params[:id]
    @payment = Payment.find_by_id(payment_id)
    @payment.update_attribute(:status, Payment::STATUS[:initiated])
    respond_to do |format|
      format.json {render json: {status: "success"}}
    end
  end

  def paypal_callback
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
          paypal_txn_id = params[:tx]
          status = params[:st]
          @payment = Payment.find_by_gm_txn_id(gm_txn_id)
          if @payment.present? && @payment.id == payment_id.to_i && @payment.amount == amount.to_f && @payment.created_at.to_i == created_at.to_i && @payment.currency == currency
            if ![Payment::STATUS[:paid], Payment::STATUS[:success]].include?(@payment.status) && @payment.amount == amount.to_f && status == "Completed"
              @payment.status = Payment::STATUS[:success]
              @payment.txn_id = paypal_txn_id
              @payment.save
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
        Rails.logger.info "Payment Notification"
        Rails.logger.info params.except("controller", "action").inspect
        Rails.logger.info ex.backtrace.join("\n") if ex.respond_to?(:backtrace)
      end
      format.html { render text: "OK" }
    end
  end
end
