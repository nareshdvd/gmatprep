class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:paypal_callback]
  def paypal_callback
    render text: "OK"
  end

  def paypal_cancel
    render text: "OK"
  end
end