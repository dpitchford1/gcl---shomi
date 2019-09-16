$ ->
  $('.toggle_view').hide()
  $('.toggle_view:first').show()
  $('.toggle_btn:first').addClass 'active'

  $('.toggle_btn').on 'click', (e) ->
    btnIndex = $('.toggle_btn').index(e.target)
    view = $($('.toggle_view')[btnIndex])

    $('.toggle_btn').removeClass 'active'
    $(e.target).addClass 'active'

    $('.toggle_view').hide()
    if view
      view.show()
