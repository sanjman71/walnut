$.fn.init_send_message_form = function() {
  $("#send_message_button").click(function() {
    // message subject is required if its visible on the pqge
    if ($("div#message_subject.required").length == 1) {
      if (!$("input#message_subject").val()) {
        alert("Please enter a message subject");
        return false;
      }
    }

    if (!$("textarea#message_body").val()) {
      alert("Please enter a message body");
      return false;
    }

    return true;
  })
}

$.fn.init_timepicker = function() {
  $(".timepicker").timepickr({convention:12});
}

$(document).ready(function() {
  $(document).init_timepicker();
  $(document).init_send_message_form();
})
