#
# Call the server to provide us with SSO login data.
#
# home_url is the url to visit on the target site when the user is not logged
# in or if there are any errors.
#
# sso_url is the url to visit on the target site to process the single sign-on.
#
# destination_url is the url to visit on the target site when single sign-on
# is successful.
#
# If requires_login is true then the user will be taken to a sign-on page on
# the current site if they are not signed in.
#
# Use @ to make this available to the inline onclick handler on the link.  See 
# http://stackoverflow.com/a/5995586.  An inline call was used to work around
# Safari caching issues.
#
# This is a better way:
# $ ->
#   $('#some_link_id').click redirect_using_sso_click_handler
#
@redirect_using_sso_click_handler = (home_url, sso_url, destination_url, requires_login) ->
  $.post('/sso_launch', {home_url: home_url, sso_url: sso_url, destination_url: destination_url, requires_login: requires_login})
    .done(redirect_handler)
    .fail(redirect_fail_handler)


redirect_handler = (response_from_server) ->
  if response_from_server.action == 'redirect_to'
    redirect_to(response_from_server)
  else if response_from_server.action == 'redirect_using_sso_to'
    redirect_using_sso_to(response_from_server)
  else
    display_generic_error()


redirect_fail_handler = (response_from_server) ->
  display_generic_error()


# Using .href allows the browser's back button and history to work as expected.
# See http://stackoverflow.com/a/16959668
redirect_to = (redirect_params) ->
  window.location.href = redirect_params.url


# Use @ so that this method is available in javascript.
@redirect_using_sso_to = (redirect_params) ->
  form = $('<form/>')
  form.attr({'action': redirect_params.url, 'method': 'post'})
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'sso_version', 'value': redirect_params.sso_version}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'username', 'value': redirect_params.username}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'timestamp', 'value': redirect_params.timestamp}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'guid', 'value': redirect_params.guid}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'user_token', 'value': redirect_params.user_token}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'language', 'value': redirect_params.language}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'destination_url', 'value': redirect_params.destination_url}))
  form.append($('<input/>').attr({'type': 'hidden', 'name': 'digital_signature', 'value': redirect_params.digital_signature}))
  $('body').append(form)    # Needed for FireFox.
  form.submit()


display_generic_error = ->
  $('#error_div_id')
    .text('Sorry - there was an internal hiccup.  Please try refreshing the page and then clicking the link again.')
    .css('display', 'block')
    .css('text-align', 'center')
    .removeClass('is-animated')
    .show()
