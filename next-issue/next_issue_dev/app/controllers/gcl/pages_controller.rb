class Gcl::PagesController < ApplicationController
  layout :resolve_layout

  caches_action :gameplus, :gameplus, :gameplus_web, :blackouts, unless: Proc.new { @session.logged? }, cache_path: Proc.new { |c| c.params.merge({lang:  I18n.locale, portal_eligible: cookies[:portal_eligible]}) }

  def frenchpackage_redirect
    session[:user_region] = rds_games_region_params[:region]
    if @current_session.logged?
      redirect_to new_order_path(order: { billing_option: 'cc'})
    else
      redirect_to new_profile_path
    end
  end

  def reset_frenchpackage
    session.delete(:user_region)
    redirect_to :back
  end

  def gameplus
  end

  def gameplus_web
    render :gameplus
  end

  private

  def resolve_layout
    case action_name
    when "gameplus_web"
      "gameplus_web"
    else
      "application"
    end
  end
  def rds_games_region_params
    params.require(:rds_games_region).permit(:region).symbolize_keys
  end

  def addload_ready(script)
    content_for(:addload_ready) {
      script .gsub(/(<script>|<\/script>)/, "")
    }
  end

end
