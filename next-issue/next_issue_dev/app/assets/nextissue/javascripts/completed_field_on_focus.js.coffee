$ ->
  $('.text-field').on 'focus', (e) ->
    $(e.target).addClass('completed-field')