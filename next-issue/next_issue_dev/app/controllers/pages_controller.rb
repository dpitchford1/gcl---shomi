class PagesController < ApplicationController

  caches_action :index, :support, unless: Proc.new { @session.logged? || session[:can_edit] }, cache_path: Proc.new { |c| c.params.merge({lang:  I18n.locale, portal_eligible: cookies[:portal_eligible]}) }

  def index
    if cookies[:portal_eligible]
      @home_page = true
      render :gateway 
    else
      @home_page = true
      @offer = Offer.current_offer
      @promo_code = PromoCode.new

      redirect_to profiles_path if @current_session.logged? 
    end
  end

  def msg
    redirect_to root_path if !session[:msg_type]
  end

  def addload_ready(script)
    content_for(:addload_ready) {
      script .gsub(/(<script>|<\/script>)/, "")
    }
  end

  def noscript(noscript)
    content_for(:noscript) {
      noscript .gsub(/(<noscript>|<\/noscript>)/, "")
    }
  end
  
  def support
  end

end
