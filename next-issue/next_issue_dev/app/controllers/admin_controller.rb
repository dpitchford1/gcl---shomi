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

  def clear_promo_codes
    Ohm.redis.call('KEYS', "PromoCode:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Promo codes successfully deleted'
  end

  def clear_tos
    Ohm.redis.call('KEYS', "Tos:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Tos successfully deleted'
  end

  def clear_questions
    Ohm.redis.call('KEYS', "Question:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Questions successfully deleted'
  end

  def clear_survey_questions
    Ohm.redis.call('KEYS', "SurveyQuestion:*").each { |key| Ohm.redis.call('DEL', key) }
    Ohm.redis.call('KEYS', "SurveyOption:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Survey Questions and Options successfully deleted'
  end

  def clear_loyalty_codes
    Ohm.redis.call('KEYS', "LoyaltyCode:*").each { |key| Ohm.redis.call('DEL', key) }
    redirect_to admin_root_path, notice: 'Loyalty codes successfully deleted'
  end

  def clear_debug_logs
    # clear the debug logs from that redis server, then switch back to original
    Ohm.redis = Redic.new(ENV["REDISCLOUD_DEBUGGER"])
    Ohm.redis.call('KEYS', "DebugLog:*").each { |key| Ohm.redis.call('DEL', key) }
    Ohm.redis = Redic.new(ENV["REDISCLOUD_URL"])
    redirect_to admin_root_path, notice: 'debug logs successfully deleted'
  end

  def clear_debug_godzilla_logs
    Ohm.redis = Redic.new(ENV["REDISCLOUD_DEBUGGER"])
    Ohm.redis.call('KEYS', "DebugGodzilla:*").each { |key| Ohm.redis.call('DEL', key) }
    Ohm.redis = Redic.new(ENV["REDISCLOUD_URL"])
    redirect_to admin_root_path, notice: 'debug godzilla logs successfully deleted'
  end
  private 

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      session[:can_edit] = true if username == "admin" && password == ENV['admin_password']
      session[:can_edit]
    end 
  end

  
end