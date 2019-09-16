alt_message = "<%= t('pages.background.alternative_message') %>"

processWsMessage = (data) ->
  if data
    json = JSON.parse(data)
    redirect = "<%= root_path %>"
    redirect = json.redirect  if json.redirect
    alt_message = ""
    alt_message = json.alt_message  if json.alt_message
    unless json.active
      window.location = redirect
    else
      $("#background_job_notice").html json.message  if json.message
      $("#background_job_modal").modal "show"
    console.log json
  return

iePoll = () ->
  intervals = [
    1
    3
    6
    10
    15
  ]
  cnt = 0
  refreshIntervalId = setInterval (->
    cnt++
    axel = Math.random() + ""
    rand_num = axel * 1000000000000000000

    if $.inArray(cnt, intervals) > -1 || cnt % 5 == 0
      url = "<%= browser.ie8? ? ENV['WEBSOCKETS_HTTP_PROXY_URL'] : ENV['WEBSOCKETS_HTTP_URL'] %>/?s=<%= session.id %>&r=" + rand_num

      $.get url, (data) ->
        processWsMessage data
        return
    return
  ), 1000  

BgWs = ->
  @ws = new WebSocket("<%= ENV['WEBSOCKETS_WS_URL'] %>/?s=<%= session.id %>")

  @ws.onopen = (evt) ->
    console.log "onopen called"
    return

  @ws.onclose = ->
    console.log "onclose called"
    return

  @ws.onmessage = (evt) ->
    console.log "onmessage called"
    processWsMessage evt.data
    return
  return

$ ->
  $("#new_session_modal").hide()  

  if window.WebSocket && <%= websockets?  %>
    bg_ws = new BgWs()
  else
    $("#background_job_modal").modal "show"
    iePoll()

  setTimeout (->
    $("#background_job_notice").html alt_message  if alt_message
    $("#background_job_cancel_button").show()
    return
  ), 15000
  return


