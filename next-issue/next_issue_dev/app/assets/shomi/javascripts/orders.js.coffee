//= require postmessage

change_state = (country) ->
  switch country
    when 'USA'
      $('[data-state=text]').hide()
      $('[data-state=ca]').hide()
      $('[data-state=us]').show()
      $('#field_creditCardState_text').prop('name', '')
      $('#field_creditCardState_ca').prop('name', '')
      $('#field_creditCardState_us').prop('name', 'field_creditCardState')
    when 'CAN'
      $('[data-state=text]').hide()
      $('[data-state=ca]').show()
      $('[data-state=us]').hide()
      $('#field_creditCardState_text').prop('name', '')
      $('#field_creditCardState_ca').prop('name', 'field_creditCardState')
      $('#field_creditCardState_us').prop('name', '')
    else
      $('[data-state=text]').show()
      $('[data-state=ca]').hide()
      $('[data-state=us]').hide()
      $('#field_creditCardState_text').prop('name', 'field_creditCardState')
      $('#field_creditCardState_ca').prop('name', '')
      $('#field_creditCardState_us').prop('name', '')
  return

$ ->
  $('input[data-redirect="true"]').on "click", ->
    window.location.href = $(this).data('link')
    return

  $("#new_credit_card").submit ->
    data = $('[data-serializable=true]').serialize()
    cc = $('#credit_card_field_creditCardNumber').val()
    data += '&masked_cc=' + Array(12).join("*") + cc.substr(cc.length - 4)
    $('#credit_card_field_passthrough1').val(escape data)


  change_state $("#credit_card_field_creditCardCountry").val()
  $("#credit_card_field_creditCardCountry").change ->
    country = $(this).val()
    change_state(country)
    return

