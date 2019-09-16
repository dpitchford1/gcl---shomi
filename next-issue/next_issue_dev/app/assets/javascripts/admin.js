//= require jquery
//= require jquery_ujs
//= require jquery-plugins/jquery.datetimepicker

$( document ).ready(function() {
    if ($('.datetimepicker') && typeof $('.datetimepicker').datetimepicker != 'undefined') {
        $('.datetimepicker').datetimepicker({format:'d-m-Y H:i'});
    }
});