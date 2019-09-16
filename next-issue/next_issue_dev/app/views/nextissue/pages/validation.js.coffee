addLoadEvent ->
  object_name = "<%= name %>"
  credit_card_validation_type = "<%= session[:exclusive_creditcard] || session[:loyalty_code].try(:validation_type) || 'any' %>"
  # Add error class to wrapper & error message
  # Errors added to select fields are directly below wrapper to avoid changing select itself
  toggleError = (name, errors, wrapper) ->
    wrapper.find(" .controls p.help-inline." + name).remove()

    if wrapper.find('[name="' + object_name + "[" + name + "]" + '"]').length > 0
      input = wrapper.find('[name="' + object_name + "[" + name + "]" + '"]')
    else if wrapper.find('[name="' + name + '"]').length > 0
      input = wrapper.find('[name="' + name + '"]')
    else
      input = $(wrapper.find('input, textarea, select').get(0))

    if errors && errors[name]
      console.log 'name: ' + name + ', message: ' + errors[name][0]
      wrapper.addClass "error"
      wrapper.find(" .controls small.help-block").remove()

      if input && input.parents('.controls').length > 0
        input.parents('.controls').append '<p class="help-inline ' + name + '">' + errors[name][0] + "</p>"
      else
        wrapper.find(".controls").append '<p class="help-inline ' + name + '">' + errors[name][0] + "</p>"

      if input
        input.removeClass('completed-field')

    else
      # Remove error from wrapper if there are no more errors in this row
      if wrapper.find('p.help-inline').length == 0
        wrapper.removeClass "error"

      if input
        input.addClass('completed-field')

    return

  # Return form row wrapper div
  getWrapper = (formId, objectName, name) ->
    selector = 'form[data-validate="' + formId + '"] *[name="' + objectName + "[" + name + "]" + '"]'
    wrapper = $(selector).parents(".form-row")

    if wrapper.size() == 0
      selector = 'form[data-validate="' + formId + '"] *[name^="' + objectName + "[" + name + "(" + '"]'
      wrapper = $(selector).parents(".form-row")
    if wrapper.size() == 0
      selector = 'form[data-validate="' + formId + '"] *[name^="' + name + '"]'
      wrapper = $(selector).parents(".form-row")
    if wrapper.size() == 0
      selector = 'form[data-validate="' + formId + '"] *[name^="' + name + '("]'
      wrapper = $(selector).parents(".form-row")

    return wrapper

  # Validate single field on focusout & all fields on form submission
  validate = (e, validate_all) ->
    wrapper = undefined
    name = undefined
    tmp_name = undefined
    form = $("form[data-validate='<%= form_id %>']")
    validation = false

    # object_name[validate] prevents profile 'update' from updating profile on single field validation( require update to post the full form with valid fields before updating)
    # validate=true forces credit card form to require the security code & credit card number
    $.post "/<%= path %>", form.serialize() + '&<%= name %>[validate]=' + validation + '&validate=true', (data) ->
      if validate_all
        errors_cnt = 0
        error = undefined
        form.find(".form-row").removeClass "error"
        form.find(".form-row p.help-inline").remove()

        for name of data.errors
          if (object_name == 'cc' || (object_name == 'order' && !$('#validate_contact_data'))) &&
            (name == 'field_phone' || name == 'phone_number' || name == 'birthdate' || name == 'field_email')
            # missing phone / dob / email on the credit card or order forms are not errors
          else
            errors_cnt += 1

            wrapper = getWrapper("<%= form_id %>", object_name, name)

            toggleError name, data.errors, wrapper

        console.log errors_cnt
        if errors_cnt == 0
          form.submit()
        else
          eventLabel = object_name + ' error messages: '
          $.each data.errors, (key, value) ->
            eventLabel = eventLabel + key + ' : \'' + value[0] + '\' '
          dataLayer.push { 'event': 'revent', 'eventCategory': 'errors', 'eventAction': 'error on the path ' + window.location.pathname, 'eventLabel', eventLabel }
      else
        name = name.replace(/\[\]$/, "")
        name = name.replace(/^.*?\[/, "")
        name = name.replace(/(\(.*?\))?]$/, "")

        toggleError name, data.errors, wrapper

        if form.find('.btn-default[type="submit"]')
          if form.find('p.help-inline').length > 0
            form.find('.btn-default[type="submit"]').addClass('btn-light')
          else
            form.find('.btn-default[type="submit"]').removeClass('btn-light')
      return

    return;

  # return true if the credit card number is not valid
  creditCardValueNotValid = (value) ->
    if credit_card_validation_type == 'amex'
      # First digit must be a 3 and second digit must be a 4 or 7. Valid length: 15 digits.
      return !/^3[4|7]\d{13}$/.test(value)
    else if credit_card_validation_type == 'mastercard'
      # First digit must be a 5 and second digit must be in the range 1 through 5 inclusive. Valid length: 16 digits.
      return !/^5[1-5]\d{14}$/.test(value)
    else if credit_card_validation_type == 'visa'
      # First digit must be a 4. Valid length: 13 or 16 digits.
      return !/^4\d{12,15}$/.test(value)
    else
      # Must be a number
      return !/^(\d+)$/.test(value)

  getValidMaximumFromName = (name) ->
    if name == 'city' || name == 'field_creditCardCity'
      return 30
    else if name == 'field_creditCardNumber'
      return 16

  getValidMinimumFromName = (name) ->
    if name == 'field_cardSecurityCode'
      return 3
    else if name == 'field_creditCardNumber'
      return 13
    else if name == 'membership_number' && $('#membership_type').val() != 'Air Miles' && $('#membership_type').val() != 'VIA Préférence' && $('#membership_type').val() != 'Scene'
      return 7

  getValidExactFromName = (name) ->
    if name == 'membership_number'
      if $('#membership_type').val() == 'Air Miles'
        return 11
      else if $('#membership_type').val() == 'VIA Préférence'
        return 7
      else if $('#membership_type').val() == 'Scene'
        return 16

  # Error messages for single field validation
  error_messages = {}
  error_messages['username'] = {blank: { username: ['<%= t('activemodel.errors.models.profile.attributes.username.blank') %>'] } }
  error_messages['email_address'] = {blank: { email_address: ['<%= t('activemodel.errors.models.profile.attributes.email_address.blank') %>'] }, invalid: { email_address: ['<%= t('activemodel.errors.models.profile.attributes.email_address.invalid') %>'] }, confirmation: { email_address: ['<%= t('activemodel.errors.models.profile.attributes.email_address.confirmation') %>'] } }
  error_messages['email_address_confirmation'] = {blank: { email_address_confirmation: ['<%= t('activemodel.errors.models.profile.attributes.email_address.blank') %>'] }, invalid: { email_address_confirmation: ['<%= t('activemodel.errors.models.profile.attributes.email_address.invalid') %>'] }, confirmation: { email_address_confirmation: ['<%= t('activemodel.errors.models.profile.attributes.email_address.confirmation') %>'] } }
  error_messages['password'] = {blank: { password: ['<%= t('errors.attributes.password.blank') %>'] }, confirmation: { password: ['<%= t('errors.attributes.password_confirmation.confirmation') %>'] }, blankConfirmation: { password: ['<%= t('errors.attributes.password.blank') %>', '<%= t('errors.attributes.password_confirmation.confirmation') %>'] } }
  error_messages['password_confirmation'] = {blank: { password_confirmation: ['<%= t('errors.attributes.password.blank') %>'] }, confirmation: { password_confirmation: ['<%= t('errors.attributes.password_confirmation.confirmation') %>'] }, blankConfirmation: { password_confirmation: ['<%= t('errors.attributes.password.blank') %>', '<%= t('errors.attributes.password_confirmation.confirmation') %>'] } }
  error_messages['question'] = {blank: { question: ['<%= t('errors.attributes.question.blank') %>']}}
  error_messages['answer'] = {blank: { answer: ['<%= t('errors.attributes.answer.blank') %>'] }, too_long: { answer: ['<%= t('errors.attributes.answer.too_long') %>'] } }
  error_messages['password_answer'] = {blank: { password_answer: ['<%= t('errors.attributes.password_answer.blank') %>'] } }
  error_messages['field_creditCardNumber'] = {blank: { field_creditCardNumber: ['<%= t('errors.attributes.field_creditCardNumber.blank') %>'] }, invalid: { field_creditCardNumber: ['<%= t('errors.attributes.field_creditCardNumber.invalid') %>'] }, too_short: { field_creditCardNumber: ['<%= t('errors.attributes.field_creditCardNumber.too_short') %>'] }, too_long: { field_creditCardNumber: ['<%= t('errors.attributes.field_creditCardNumber.too_long') %>'] } }
  error_messages['field_creditCardAddress1'] = {blank: { field_creditCardAddress1: ['<%= t('errors.attributes.field_creditCardAddress1.blank') %>'] } }
  error_messages['field_cardSecurityCode'] = { blank: { field_cardSecurityCode: ['<%= t('errors.attributes.field_cardSecurityCode.blank') %>'] }, invalid: { field_cardSecurityCode: ['<%= t('errors.attributes.field_cardSecurityCode.invalid') %>'] }, too_short: { field_cardSecurityCode: ['<%= t('errors.attributes.field_cardSecurityCode.too_short') %>'] } }
  error_messages['field_creditCardCity'] = {blank: { field_creditCardCity: ['<%= t('errors.attributes.field_creditCardCity.blank') %>'] }, too_long: { field_creditCardCity: ['<%= t('errors.attributes.field_creditCardCity.too_long') %>'] } }
  error_messages['field_creditCardExpirationMonth'] = {blank: { field_creditCardExpirationMonth: ['<%= t('errors.attributes.field_creditCardExpirationMonth.blank') %>'] } }
  error_messages['field_creditCardExpirationYear'] = {blank: { field_creditCardExpirationYear: ['<%= t('errors.attributes.field_creditCardExpirationYear.blank') %>'] } }
  error_messages['field_creditCardHolderName'] = {blank: { field_creditCardHolderName: ['<%= t('errors.attributes.field_creditCardHolderName.blank') %>'] } }
  error_messages['field_creditCardPostalCode'] = {blank: { field_creditCardPostalCode: ['<%= t('errors.attributes.field_creditCardPostalCode.blank') %>'] }, invalid: { field_creditCardPostalCode: ['<%= t('errors.attributes.field_creditCardPostalCode.invalid') %>'] } }
  error_messages['field_creditCardState'] = {blank: { field_creditCardState: ['<%= t('errors.attributes.province.blank') %>'] } }
  error_messages['province'] = {blank: { province: ['<%= t('errors.attributes.province.blank') %>'] } }
  error_messages['tos'] = {blank: { tos: ['<%= t('errors.attributes.tos.accepted') %>'] } }
  error_messages['rogers_account_token'] = {blank: { rogers_account_token: ['<%= t('errors.attributes.rogers_account_token.blank') %>'] } }
  error_messages['invalid'] = ['<%= t('errors.messages.invalid') %>']
  error_messages['first_name'] = {blank: { first_name: ['<%= t('errors.attributes.first_name.blank') %>'] }, invalid: { first_name: ['<%= t('errors.attributes.first_name.invalid') %>'] } }
  error_messages['last_name'] = {blank: { last_name: ['<%= t('errors.attributes.last_name.blank') %>'] }, invalid: { last_name: ['<%= t('errors.attributes.last_name.invalid') %>'] } }
  error_messages['street'] = {blank: { street: ['<%= t('errors.attributes.field_creditCardAddress1.blank') %>'] } }
  error_messages['city'] = {blank: { city: ['<%= t('errors.attributes.field_creditCardCity.blank') %>'] } }
  error_messages['postal_code'] = {blank: { postal_code: ['<%= t('errors.attributes.field_creditCardPostalCode.blank') %>'] }, invalid: { postal_code: ['<%= t('errors.attributes.field_creditCardPostalCode.invalid') %>'] } }
  error_messages['phone_number'] = {blank: { phone_number: ['<%= t('activemodel.errors.models.order.attributes.phone_number.blank') %>'] }, invalid: { phone_number: ['<%= t('activemodel.errors.models.order.attributes.phone_number.invalid') %>'] } }
  error_messages['birthdate'] = {blank: { birthdate: ['<%= t('errors.attributes.birthdate.blank') %>'] } }
  error_messages['membership_number'] = { invalid: { membership_number: ['<%= t('errors.attributes.membership_number.invalid') %>'] }, too_short: { membership_number: ['<%= t('errors.attributes.membership_number.too_short') %>'] }, wrong_length: { membership_number: ['<%= t('errors.attributes.membership_number.wrong_length') %>'] } }
  # Validate single field on focusout
  validateField = (e) ->
    form = $(this).parents("form")
    wrapper = $(this)
    value = $(e.target).val()
    type = $(e.target).attr('type')
    name = $(e.target).attr('name')
    if name
      name = name.replace(/\[\]$/, "")
      name = name.replace(/^.*?\[/, "")
      name = name.replace(/(\(.*?\))?]$/, "")
    else
      return;
    resulting_error_messages = {}

    if $(e.target).hasClass('optional')
      return;

    if type == 'password'
      # Validate password field
      otherName = 'password_confirmation'
      if name == otherName
        otherName = 'password'
      otherWrapper = getWrapper("<%= form_id %>", object_name, otherName)
      otherInput = otherWrapper.find('[name="' + otherName + '"]')
      if otherInput.length == 0
        otherInput = $(otherWrapper.find('input, textarea, select').get(0))

      if value == null || value == '' || value.length > 16 || value.length < 7 || !/^(?=.*[0-9])(?=.*[a-zA-Z])[a-zA-Z0-9]+$/.test(value)
        # if this field is invalid/blank add the error to itself
        if otherInput.length > 0 && otherInput.val() != value
          resulting_error_messages = error_messages[name]['blankConfirmation']
        else
          resulting_error_messages = error_messages[name]['blank']
        toggleError name, resulting_error_messages, wrapper
      else
        # if the passwords don't match, add the error to the other field & clear this field
        if otherInput.length > 0 && otherInput.val() != value
          resulting_error_messages = error_messages[name]['confirmation']
          toggleError name, {}, wrapper
        else
          # clear both fields
          resulting_error_messages = {}
          toggleError name, resulting_error_messages, wrapper
          toggleError otherName, resulting_error_messages, wrapper
        toggleError name, resulting_error_messages, otherWrapper
    else
      # Validate text fields
      if value == null || value == ''
        if error_messages[name]
          if error_messages[name]['blank']
            resulting_error_messages = error_messages[name]['blank']
          else
            resulting_error_messages = error_messages[name]['invalid']
        else
          resulting_error_messages[name] = error_messages['invalid']
      else if name == 'answer' && value.length > 40
        resulting_error_messages = error_messages[name]['too_long']
      else if (name == 'email_address' || name == 'email_address_confirmation') && !/^([\w\!\#\z\%\&\'\*\+\-\/\=\?\\A\`{\|\}\~]+\.)*[\w\+-]+@((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z])\.)+[a-z]{2,6})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)$/.test(value)
        resulting_error_messages = error_messages[name]['invalid']
      else if name == 'email_address' || name == 'email_address_confirmation'
        otherName = 'email_address_confirmation'
        if name == otherName
          otherName = 'email_address'
        otherWrapper = getWrapper("<%= form_id %>", object_name, otherName)
        otherInput = otherWrapper.find('[name="' + otherName + '"]')
        if otherInput.length == 0
          otherInput = $(otherWrapper.find('input, textarea, select').get(0))
        if otherInput.length > 0 && otherInput.val() != value
          resulting_error_messages = error_messages[name]['confirmation']
        else
          resulting_error_messages = {}
          toggleError otherName, resulting_error_messages, otherWrapper
      else if (name == 'postal_code' || name == 'field_creditCardPostalCode') && !/^([a-zA-Z]\d[a-zA-z]( )?\d[a-zA-Z]\d)$/.test(value)
        resulting_error_messages = error_messages[name]['invalid']
      else if name == 'phone_number' && !/^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/.test(value)
        resulting_error_messages = error_messages[name]['invalid']
      else if name == 'tos' && !$(e.target).is(':checked')
        resulting_error_messages = error_messages[name]['blank']
      else if name == 'field_cardSecurityCode' && !/^(\d+)$/.test(value)
        resulting_error_messages = error_messages[name]['invalid']
      else if name == 'field_creditCardNumber' && creditCardValueNotValid(value)
        resulting_error_messages = error_messages[name]['invalid']
      else if name == 'membership_number' && !/^(\d+)$/.test(value)
        resulting_error_messages = error_messages[name]['invalid']
      else if (name == 'city' || name == 'field_creditCardCity' || name == 'field_creditCardNumber') && value.length > getValidMaximumFromName(name)
        resulting_error_messages = error_messages[name]['too_long']
      else if (name == 'field_cardSecurityCode' || name == 'field_creditCardNumber' || name == 'membership_number') && (getValidMinimumFromName(name) && value.length < getValidMinimumFromName(name))
        resulting_error_messages = error_messages[name]['too_short']
      else if name == 'membership_number' && (getValidExactFromName(name) && value.length != getValidExactFromName(name))
        # Make sure the exact value is defined before checking the length error
        resulting_error_messages = error_messages[name]['wrong_length']
      else
        resulting_error_messages = {}

      # remove error if the loyalty has been set to 'none'
      if name == 'membership_number' && (value == null || value == '' || /^none$/i.test(value))
        resulting_error_messages = {}

      toggleError name, resulting_error_messages, wrapper

    if form.find('.btn-default[type="submit"]')
      if form.find('p.help-inline').length > 0
        form.find('.btn-default[type="submit"]').addClass('btn-light')
      else
        form.find('.btn-default[type="submit"]').removeClass('btn-light')

    return;

  $("form[data-validate='<%= form_id %>'] .form-row").on 'keyup', validateField
  $("form[data-validate='<%= form_id %>'] .form-row").on 'focusout', validateField

  $("form[data-validate='<%= form_id %>'] input[type=submit]").on 'click', ->
    validate this, true
    false

  return
