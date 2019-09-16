# Hack to show placeholder in ie 8 by replacing value of text fields with their placeholder
# Also replaces password type with text to make them visible

$ ->
  $('.text-field').each (index, elem) ->
    element = $(elem)
    if element && element.val() == ''
      element.val(element.attr('placeholder'))

  $('.text-field').on 'focus', (e) ->
    element = $(e.target)
    if element && element.val() == element.attr('placeholder')
      element.val('')

  $('.text-field').on 'focusout', (e) ->
    element = $(e.target)
    if element && element.val() == ''
      element.val(element.attr('placeholder'))

