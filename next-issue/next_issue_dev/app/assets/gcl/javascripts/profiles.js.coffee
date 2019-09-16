$ ->
  $('.check-tos').on "click", ->
    $("#tos_modal").modal "show" if $(".check-tos").is ":checked"
    return