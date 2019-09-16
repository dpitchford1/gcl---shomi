addLoadEvent ->
  object_name = "<%= name %>"
  toggleError = (name, errors, wrapper) ->
    if errors[name]
      wrapper.addClass "error"
      wrapper.find(" .controls p.help-inline").remove()
      wrapper.find(" .controls").append "<p class=\"help-inline\">" + errors[name][0] + "</p>"
    else
      wrapper.removeClass "error"
      wrapper.find(" .controls p.help-inline").remove()
    return

  validate = (e, validate_all) ->
    wrapper = undefined
    name = undefined
    form = undefined
    if validate_all is `undefined`
      form = $(this).parents("form")
      wrapper = $(this)
      name = $(this).find("input, textarea, select").get(0).name
    else
      form = $("form[data-validate='<%= form_id %>']")

    $.post "/<%= path %>", form.serialize() + '&<%= name %>[validate]=true&validate=true', (data) ->
      if validate_all
        errors_cnt = 0
        error = undefined
        form.find(".form-row").removeClass "error"
        form.find(".form-row .controls p.help-inline").remove()
        
        for name of data.errors
          errors_cnt += 1
          selector = 'form[data-validate="<%= form_id %>"] *[name="' + object_name + "[" + name + "]" + '"]' 
          wrapper = $(selector).parents(".form-row")
          if wrapper.size() == 0
            selector = 'form[data-validate="<%= form_id %>"] *[name^="' + object_name + "[" + name + "(" + '"]'
            wrapper = $(selector).parents(".form-row")
          if wrapper.size() == 0
            selector = 'form[data-validate="<%= form_id %>"] *[name^="' + name + '"]'
            wrapper = $(selector).parents(".form-row")
          if wrapper.size() == 0
            selector = 'form[data-validate="<%= form_id %>"] *[name^="' + name + '("]'
            wrapper = $(selector).parents(".form-row")            

          toggleError name, data.errors, wrapper

        console.log errors_cnt
        form.submit() if errors_cnt == 0
      else
        name = name.replace(/\[\]$/, "")
        name = name.replace(/^.*?\[/, "")
        name = name.replace(/(\(.*?\))?]$/, "")

        toggleError name, data.errors, wrapper
      return

    return

  $("form[data-validate='<%= form_id %>'] .form-row").focusout validate

  $("form[data-validate='<%= form_id %>'] input[type=submit]").click ->
    validate this, true
    false

  return
