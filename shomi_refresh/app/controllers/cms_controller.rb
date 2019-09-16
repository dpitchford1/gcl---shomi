class CmsController < ActionController::Base
  before_action :authenticate, except: [:show]
  layout 'admin'


  private 

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "admin" && password == ENV['admin_password']
    end 
  end
 
end