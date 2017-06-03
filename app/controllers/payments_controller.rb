class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:paypal_callback]
  skip_before_action :verify_authenticity_token, only: [:notification]
  def paypal_callback
    # plan_id = params[:item_number]
    # paypal_txn_id = params[:tx]
    # status = params[:st]
    # amount = params[:amt]
    # currency = params[:cc]
    binding.pry
    render text: "OK"
  end

  def paypal_cancel
    binding.pry
    render text: "OK"
  end

  def notification
    binding.pry
  end
end
