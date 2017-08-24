load Rails.root.join("app", "models", "payment.rb").to_s
load Rails.root.join("app", "models", "payment_method.rb").to_s
load Rails.root.join("app", "models", "invoice.rb").to_s
load Rails.root.join("app", "models", "plan.rb").to_s
load Rails.root.join("app", "models", "subscription.rb").to_s
GmatricPayment = Payment
GmatricInvoice = Invoice
GmatricPaymentMethod = PaymentMethod
GmatricPlan = Plan
GmatricSubscription = Subscription
#PayuIndia.test_url = 'https://test.payu.in/_payment.php'
### PayuIndia.test_url = 'https://secure.payu.in/_payment.php'
### PayuIndia.production_url = 'https://secure.payu.in/_payment.php'