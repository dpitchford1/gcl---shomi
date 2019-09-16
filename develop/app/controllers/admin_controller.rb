require 'database_cleaner'

class AdminController < ActionController::Base
  before_action :authenticate
  protect_from_forgery with: :exception
  layout 'admin'

  def clean_up

  	DatabaseCleaner.strategy = :truncation, {:only => %w[PromoCode* Account* Order* Session* Profile*]}
  	DatabaseCleaner.clean

  	redirect_to "/admin"
  end

  def clean_up_partial
    SchedulerWorker.perform_async(:db_clean)

    redirect_to "/admin"
  end

  def clear_cache
    Ohm.redis.call('KEYS', "cache:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Cache successfully cleared'
  end

  def clear_cms
    Ohm.redis.call('KEYS', "Cms:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'CMS successfully cleared'
  end

  def clear_offers
    Ohm.redis.call('KEYS', "Offer:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Offers successfully deleted'
  end
  private 

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      session[:can_edit] = true if username == "admin" && password == ENV['admin_password']
      session[:can_edit]
    end 
  end

  
end