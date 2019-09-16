require 'sidekiq/web'


DefaultRails::Application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  namespace :admin do
    root 'pages#index'
    resources :feature_flags
    resources :debug_logs, only: [:index]
  end

  get 'gameplus'                   => 'gcl/pages#gameplus', as: 'gameplus'
  get 'blackouts'                  => 'gcl/pages#blackouts', as: 'blackouts'
  get 'french-package-details'     => 'gcl/pages#frenchpackage', as: 'frenchpackage'
  post 'frenchpackage_redirect'    => 'gcl/pages#frenchpackage_redirect'
  get 'reset_frenchpackage'        => 'gcl/pages#reset_frenchpackage'
  get 'gameplus_web'               => 'gcl/pages#gameplus_web', as: 'gameplus_web'
  get 'frequently-asked-questions' => 'gcl/pages#faq', as: 'faq'
  get 'getting-started'            => 'gcl/pages#get_started', as: 'get_started'

  namespace :cms do
    get 'sections/export'                             => 'sections#export'
    post 'sections/import'                            => 'sections#import'
    post 'sections/preview'                           => 'sections#preview'
    get 'sections/add_version/:section'               => 'sections#add_version'
    get 'sections/delete_version/:section/:version'   => 'sections#delete_version'
    get 'pages/iframe'                                => 'pages#iframe'
    post "mercury_update"                            => "pages#mercury_update"


    resources :pages
    resources :sections
    resources :section_versions
  end

  get 'admin/clear_cache'       => 'admin#clear_cache'
  get 'admin/clear_cms'         => 'admin#clear_cms'
  get 'admin/clear_offers'      => 'admin#clear_offers'
  get 'admin/clear_promo_codes' => 'admin#clear_promo_codes'
  get 'admin/clear_tos'         => 'admin#clear_tos'
  get 'admin/clear_questions'           => 'admin#clear_questions'
  get 'admin/clear_survey_questions'    => 'admin#clear_survey_questions'
  get 'admin/clear_loyalty_codes'       => 'admin#clear_loyalty_codes'
  get 'admin/clear_debug_logs'          => 'admin#clear_debug_logs'
  get 'admin/clear_debug_godzilla_logs' => 'admin#clear_debug_godzilla_logs'
  get "admin/debug_logs/(type/:type)/(api_call/:api_call)/(error_type/:error_type)"  => 'admin/debug_logs#index'
  get "admin/download_csv"                                                           => 'admin/debug_logs#download_csv'

  get 'admin/clean_up'          => 'admin#clean_up'
  get 'admin/clean_up_partial'  => 'admin#clean_up_partial'

  root 'pages#index'

  get 'api/eligible/:username'      => 'api#eligible', :constraints => { :username => /[^\/]+/ }
  get 'api/optin_list'              => 'api#optin_list'
  
  resources :sessions, except: [:edit, :destroy, :show, :index, :update, :new]
  get 'logout'                    => 'sessions#destroy', as: 'get_logout'
  delete 'logout'                 => 'sessions#destroy', as: 'logout'
  get 'signin'                     => 'sessions#new', as: 'new_session'
  get 'secure/auth'                     => 'sessions#new'
  get 'secure/auth/basic'          => 'sessions#new', offer_type: "basic"
  get 'secure/auth/premium'          => 'sessions#new', offer_type: "premium"
  get 'siteminderagent/forms/login.fcc' => 'sessions#new'
  get 'background_ping'            => 'sessions#background_ping'
  get 'background_cancel'          => 'sessions#background_cancel'
  get 'clear_eligible'             => 'sessions#clear_eligible'

  get  'sso_version'              => 'sso#version'
  post 'sso_launch'               => 'sso#launch'
  post 'sso_land'                 => 'sso#land'
  get  'sso_portal_links'         => 'sso#portal_links'

  get "cookie_sso"                   => 'sessions#cookie_sso'

  resources :profiles, except: [:new, :edit, :destroy, :show, :update]
  get '/profiles/new', to: redirect("/register", status: 301)
  get 'register'                  => 'profiles#new', as: 'new_profile'
  post 'profiles/promo_code'      => 'profiles#promo_code', as: 'promo_code'
  get 'profiles/promo_business'   => 'profiles#promo_business', as: 'promo_business'
  get 'profiles/edit'             => 'profiles#edit', as: 'edit_profile'
  get 'profiles/accounts'         => 'profiles#accounts'
  post 'profiles/search_accounts' => 'profiles#search_accounts'
  post 'profiles/link_accounts'   => 'profiles#link_accounts'
  patch 'profiles'                => 'profiles#update', as: 'profile'
  get 'email_check'               => 'profiles#email_check', as: 'profile_email_check'
  post 'email_check'               => 'profiles#email_check', as: 'email_check'

  get 'orders/callback'           => 'orders#callback'
  get 'orders/history'            => 'orders#history', as: 'billing'
  get 'orders/promo_contact'      => 'orders#promo_contact', as: 'promo_contact'
  post 'orders/summary'           => 'orders#order_summary', as: 'order_summary'
  post 'orders/order_submit'      => 'orders#order_submit', as: 'order_submit'
  post 'orders/verify_cc'         => 'orders#verify_cc', as: 'verify_cc'
  post 'cancel_orders'            => 'orders#cancel_order', as: 'cancel_order'
  post 'update_order_offer'                   => 'orders#update', as: 'update_order_offer'

  resources :orders, except: [:edit, :update]

  get 'cancel_subscription_survey'               => 'cancel_orders#cancel_subscription_survey', as: 'cancel_subscription_survey'
  post 'cancel_subscription_survey'               => 'cancel_orders#cancel_subscription_survey', as: 'cancel_subscription'
  get 'cancel_order_subscription'               => 'cancel_orders#cancel_order_subscription', as: 'cancel_order_subscription'
  post 'cancel_order_subscription'               => 'cancel_orders#cancel_order_subscription', as: 'cancel_order_subscription_post'
  post 'cancel_subscription_confirmation'               => 'cancel_orders#cancel_order', as: 'cancel_subscription_confirmation'
  post 'apply_cancel_promo'               => 'cancel_orders#apply_cancel_promo', as: 'apply_cancel_promo'

  get 'tos'                     => 'tos#show'
  get 'tos/:id'                 => 'tos#show'
  get 'info'                    => 'tos#appinfo'

  #get 'getting-started'          => 'pages#support', as: 'support'
  get '/support', to: redirect("/getting-started", status: 301)
  get 'available-devices'        => 'pages#devices', as: 'devices'
  get 'gateway'                  => 'pages#gateway', as: 'gateway'


  get 'msg'                     => 'pages#msg'
  
  get 'forgot_password'         => 'profiles#forgot_password'
  post 'forgot_password_email'  => 'profiles#forgot_password_email'
  get 'forgot_password_hint'    => 'profiles#forgot_password_hint'
  post 'forgot_password_answer' => 'profiles#forgot_password_answer'
  get 'change_password'         => 'profiles#change_password'
  post 'change_password'        => 'profiles#change_password_post'

  #old nextissue routes causing 400 errors
  get 'resources/:any/:id'        => 'pages#msg'
  get 'siteminderagent/forms/:id' => "sessions#new"
  post 'siteminderagent/forms/:id' => "sessions#new"
  get 'secure/api/:a/:b' => "pages#msg"
  get 'secure/accountsummary' => "pages#msg"
  

  # temporary register testing pages routes
  get 'rogers_sign_in_or_up'      => 'nextissue/register#rogers_sign_in_or_up', as: 'new_session_or_new_profile'
  get 'redemption'                  => 'nextissue/register#redemption', as: 'redemption'
  get 'secure/common/redemption'                  => 'nextissue/register#redemption'
  post 'redemption_codes'                  => 'profiles#create', as: 'redemption_codes'
  post 'redemption_code_check'                  => 'nextissue/register#redemption_code_check', as: 'redemption_code_check'

  mount Mercury::Engine => '/'
  DynamicRouter.load
end
