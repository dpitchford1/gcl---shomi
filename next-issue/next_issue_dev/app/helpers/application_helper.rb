module ApplicationHelper

  def websockets?
    if browser.chrome? && browser.version.to_i < 15
      return 0
    elsif browser.firefox? && browser.version.to_i < 6
      return 0
    elsif browser.safari? && browser.version.to_i < 6
      return 0
    elsif browser.opera? && browser.version.to_i < 15
      return 0
    elsif browser.name =~ /android/i && browser.version.to_f < 4.4
      return 0
    end
    1
  end

	def page_title
	  (content_for(:title) + ' – ' if content_for?(:title)).to_s + t('titles.default').html_safe
	end

  def live_chat_url
    content_for(:live_chat_url) || t('live_chat.default')
  end 

  def page_name
    if params[:controller] == 'profiles' && params[:action] == 'index'
      name = @current_session.profile && @current_session.profile.eligible? ? 'eligible user profile page' : 'ineligible profile page' 
    elsif   params[:controller] == 'orders' && params[:action] == 'new'
      name = "#{@order ? @order.billing_option : ''} order page"
    elsif   params[:controller] == 'orders' && params[:action] == 'order_summary'
      name = "#{@order ? @order.billing_option : ''} order review page"
    else
      name = CONFIG[:page_names][params[:controller].to_sym] && CONFIG[:page_names][params[:controller].to_sym]["#{request.method.downcase}_#{params[:action]}".to_sym] ? CONFIG[:page_names][params[:controller].to_sym]["#{request.method.downcase}_#{params[:action]}".to_sym] : page_title
    end
    name
  end

  def ajax_validation(name, path=nil, form_number=nil, validation='validation.js')
    path.gsub! /^\//, '' if path
    form_id = form_number ? "#{name}.#{form_number}" : name
    "<script>#{render(:template =>"/pages/#{validation}", :layout => nil , :locals => { :name => name, form_id: form_id, path: path || name.to_s.pluralize }).to_s}</script>".html_safe
  end

end



