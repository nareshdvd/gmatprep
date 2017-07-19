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
