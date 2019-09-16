$ ->
  if $(".promo-row.error")
    fade_time = 4000
    promo_field = $('.promo-row.error').find('.text-field')
    promo_field.animate({borderColor: "#cacdce"}, fade_time)
    promo_submit_button = $(".promo-row.error").find('.btn-error')
    promo_submit_button.animate({backgroundColor: "#d6f2f6"}, fade_time)

    setTimeout  ( ->
      translated_apply_text = $('.apply-text').text()
      promo_submit_button.val translated_apply_text
      promo_submit_button.addClass 'btn-light'
      promo_submit_button.removeClass 'btn-error'
    ), fade_time

