Rails.application.routes.draw do
  resources :categories
  resources :levels
  resources :questions
  resources :passages
  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  get 'score_schemes' => 'score_schemes#index', as: 'index_score_schemes'
  post 'score_schemes' => 'score_schemes#update_all', as: 'update_score_schemes'
  get '/tests/finished' => 'candidates#finished_tests', as: :finished_tests
  get '/tests/remaining' => 'candidates#remaining_tests', as: :remaining_papers
  get '/tests/:subscription_id/new' => 'papers#new', as: :new_test
  get '/tests/:subscription_id/instructions/:step_number' => "papers#instructions", as: :paper_instructions
  get '/tests/:paper_id/finish' => "papers#test_finish", as: :paper_finish
  get '/tests/:paper_id/score' => "papers#show_score", as: :paper_score
  post '/tests/:paper_id/finish' => "papers#finish_test", as: :finish_paper
  get '/:test_action/test/:paid_info' => "candidates#start_test", as: :start_test
  get '/test/:paper_id/questions/:question_number' => "papers#question", as: "papers_question"
  patch '/test/:paper_id/questions/:question_number' => "papers#answer_question", as: "papers_question_answer"
  get '/buy/new' => "candidates#buy_new", as: :buy_new
  get '/users' => "home#index_users", as: :index_users
  delete 'candidates/:candidate_id/tests/destroy' => 'home#destroy_papers', as: :destroy_tests

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
  }
  post "/payment/:payment_method/:plan_id/init" => "payments#init_payment", as: :payment_init
  get "/payment/:payment_method/success" => "payments#payment_success_callback", as: :payment_success_callback
  post "/payment/payu/success" => "payments#payu_callback"
  post "/payment/payu/cancel" => "payments#payu_cancel"
  get "/payment/:payment_method/cancel" => "payments#payment_cancel_callback", as: :payment_cancel_callback
  get "/payment/:payment_method/:payment_id/thankyou" => "payments#thankyou", as: :payment_thankyou
  get "/plans" => "plans#candidate_index", as: :plans_to_buy
  post "/plans/:id/init_subscribe" => "plans#init_subscribe", as: :init_subscribe_to_plan

  post "/paypal/notification" => "payments#notification", as: :payment_notification

  get "/report/:paper_id" => "reports#index", as: :report_index
  get "/report/:paper_id/performance-charts" => "reports#charts", as: :report_charts

  get "/admins/questions/:id" => "admins#question", as: :admin_question
  post "/admins/questions/:id" => "admins#question", as: :post_admin_question

  get "/home" => "candidates#home", as: :my_home
  get "/about_us" => "home#about_us", as: :about_us
  get "/contact_us" => "home#contact_us", as: :contact_us
  post "/contact_us" => "home#contact_us", as: :post_contact_us
  get "/disclaimer" => "home#disclaimer", as: :disclaimer
  get "/mytest" => "home#test"
  root "home#index"
end
