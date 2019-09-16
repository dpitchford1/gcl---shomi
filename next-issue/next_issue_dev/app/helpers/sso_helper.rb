module SsoHelper

  # Adapted from the source for link_to.
  # See http://apidock.com/rails/ActionView/Helpers/UrlHelper/link_to
  def sso_link_to(name = nil, options = nil, html_options = nil, &block)
    html_options, options, name = options, name, block if block_given?
    options ||= {}

    html_options = convert_options_to_data_attributes(options, html_options)

    home_url = url_for(options)

    sso_url = html_options['sso_url']
    html_options = html_options.except('sso_url')

    destination_url = html_options['destination_url']
    html_options = html_options.except('destination_url')

    requires_login = (html_options['requires_login'].to_s == 'true')
    html_options = html_options.except('requires_login')

    html_options['href'] = '#'
    html_options['onclick'] = build_onclick_js(home_url, sso_url, destination_url, requires_login)

    content_tag(:a, name || home_url, html_options, &block)
  end

  private

  def build_onclick_js(home_url, sso_url, destination_url, requires_login)
    "redirect_using_sso_click_handler(#{build_url_js(home_url)}, #{build_url_js(sso_url)}, #{build_url_js(destination_url)}, #{requires_login});"
  end

  # "/abc/def" => "'/abc/def'"
  # nil => "null"
  def build_url_js(url)
    url.nil? ? "null" : "'#{url}'"
  end
end
