require_relative '../test_helper'


 #  <%= sso_link_to "NHL.COM", "http://www.nhl.com", sso_url: ENV['nhl_sso_url'], requires_login: true,
 #    class: "block", :rel => "external", title: t('text.visit_nhl') %>
class SsoHelperTest < ActionView::TestCase
  test 'it returns an "a" link' do
    assert_dom_equal %{<a href="#" onclick="redirect_using_sso_click_handler(&#39;http://www.example.com&#39;, &#39;http://www.example.com/sso&#39;, &#39;/something&#39;, false);">Example</a>}, 
      sso_link_to( 'Example', 'http://www.example.com', sso_url: 'http://www.example.com/sso', destination_url: '/something', requires_login: false )
  end

  test 'it passes null for the sso_url when it is missing' do
    assert_dom_equal %{<a href="#" onclick="redirect_using_sso_click_handler(&#39;http://www.example.com&#39;, null, &#39;/something&#39;, false);">Example</a>}, 
      sso_link_to( 'Example', 'http://www.example.com', destination_url: '/something', requires_login: false )
  end

  test 'it passes null for the destination_url when it is missing' do
    assert_dom_equal %{<a href="#" onclick="redirect_using_sso_click_handler(&#39;http://www.example.com&#39;, &#39;http://www.example.com/sso&#39;, null, false);">Example</a>}, 
      sso_link_to( 'Example', 'http://www.example.com', sso_url: 'http://www.example.com/sso', requires_login: false )
  end

  test 'it passes false to the click handler if the requires_login arg is missing' do
    assert_dom_equal %{<a href="#" onclick="redirect_using_sso_click_handler(&#39;http://www.example.com&#39;, null, null, false);">Example</a>}, 
      sso_link_to( 'Example', 'http://www.example.com' )
  end

  test 'it passes true to the click handler if the requires_login arg is true' do
    assert_dom_equal %{<a href="#" onclick="redirect_using_sso_click_handler(&#39;http://www.example.com&#39;, null, null, true);">Example</a>}, 
      sso_link_to( 'Example', 'http://www.example.com', requires_login: true )
  end

  test 'it passes false to the click handler if the requires_login arg is neither true or false' do
    assert_dom_equal %{<a href="#" onclick="redirect_using_sso_click_handler(&#39;http://www.example.com&#39;, null, null, false);">Example</a>}, 
      sso_link_to( 'Example', 'http://www.example.com', requires_login: 'oops' )
  end
end
