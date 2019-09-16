require 'sidekiq/web'


DefaultRails::Application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  namespace :admin do
    root 'pages#index'
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

  get 'admin/clean_up'          => 'admin#clean_up'
  get 'admin/clean_up_partial'  => 'admin#clean_up_partial'

  root 'pages#index'

  get 'api/eligible/:username'      => 'api#eligible', :constraints => { :username => /[^\/]+/ }
  get 'api/optin_list'              => 'api#optin_list'
  
  resources :sessions, except: [:edit, :destroy, :show, :index, :update, :new]
  delete 'logout'                 => 'sessions#destroy', as: 'logout'
  get 'signin'                     => 'sessions#new', as: 'new_session'
  get 'background_ping'            => 'sessions#background_ping'
  get 'background_cancel'          => 'sessions#background_cancel'
  get 'clear_eligible'             => 'sessions#clear_eligible'

  get  'sso_version'              => 'sso#version'
  post 'sso_launch'               => 'sso#launch'
  post 'sso_land'                 => 'sso#land'
  get  'sso_portal_links'         => 'sso#portal_links'

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

  get 'orders/callback'           => 'orders#callback'
  get 'orders/history'            => 'orders#history', as: 'billing'
  get 'orders/promo_contact'      => 'orders#promo_contact', as: 'promo_contact'
  post 'orders/summary'           => 'orders#order_summary', as: 'order_summary'
  post 'orders/order_submit'      => 'orders#order_submit', as: 'order_submit'
  post 'orders/verify_cc'         => 'orders#verify_cc', as: 'verify_cc'

  resources :orders, except: [:edit, :update]


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

  mount Mercury::Engine => '/'
  DynamicRouter.load
end
