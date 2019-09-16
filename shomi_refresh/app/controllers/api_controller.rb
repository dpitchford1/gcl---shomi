class ApiController < ActionController::Base
  respond_to :json

  before_action :restrict_access


  def eligible
    profile = Profile.find(username: params[:username]).first
    if !profile
      render json: {error: "Not found"}, status: 404
    else
      render json: {eligible: profile.eligible?, entitlement: profile.entitlement}
    end
  end

  def optin_list
    list = []
    keys = OPTIN_REDIS.keys('optin:*')
    values = OPTIN_REDIS.mget(keys)
    keys.each.with_index(0) do |key,i|
      list << key.gsub(/^optin:/, '') + "," + values[i]
    end
    response.header["Content-type"] = 'text/plain'
    response.header["Content-Disposition"] = "attachment; filename=\"portal-optin-list-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\""
    render text: list.join("\n")
  end

  private

  def restrict_access
    unless  authenticate_with_http_token { |token, options| token ==  ENV['gcl_api_key'] } || params[:token] == ENV['gcl_api_key']
      render json: {error: "Not Authorized"}, status: 401 
    end
  end
end