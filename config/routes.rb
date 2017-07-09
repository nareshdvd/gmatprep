Rails.application.routes.draw do
  resources :categories
  resources :levels
  resources :questions
  resources :passages
  authenticate :user, lambda { |u| u.has_role? :admin } do
    mount Sidekiq::Web => '/sidekiq'
  end
  get 'score_schemes' => 'score_schemes#index', as: 'index_score_schemes'
  post 'score_schemes' => 'score_schemes#update_all', as: 'update_score_schemes'
  get 'papers/:subscription_id/new' => 'papers#new', as: :new_test
  get 'papers/:subscription_id/instructions/:step_number' => "papers#instructions", as: :paper_instructions
  get 'papers/:paper_id/finish' => "papers#test_finish", as: :paper_finish
  get 'papers/:paper_id/score' => "papers#show_score", as: :paper_score
  post 'papers/:paper_id/finish' => "papers#finish_test", as: :finish_paper
  get '/users' => "home#index_users", as: :index_users
  delete 'candidates/:candidate_id/papers/destroy' => 'home#destroy_papers', as: :destroy_tests
  get 'papers/test', as: "test"
  get '/test/:paper_id/questions/:question_number' => "papers#question", as: "papers_question"
  patch '/test/:paper_id/questions/:question_number' => "papers#answer_question", as: "papers_question_answer"
  get 'home/index'
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
  }
  post "/payment/init" => "payments#init_payment", as: :payment_init
  get "/payment/paypal/success" => "payments#paypal_callback", as: :paypal_success
  get "/payment/paypal/cancel" => "payments#paypal_cancel", as: :paypal_cancel
  post "/plans/:id/init_subscribe" => "plans#init_subscribe", as: :init_subscribe_to_plan
  post "/paypal/notification" => "payments#notification", as: :payment_notification
  get "/report/:paper_id" => "reports#index", as: :report_index
  get "/report/:paper_id/performance-charts" => "reports#charts", as: :report_charts
  get "/admins/questions/:id" => "admins#question", as: :admin_question
  post "/admins/questions/:id" => "admins#question", as: :post_admin_question
  get "/testingnew" => "home#testingnew"
  root "home#index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  match "*php" => "home#testing", via: [:get, :post]
end
