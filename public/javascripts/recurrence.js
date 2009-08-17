var $current_recurrence_type = '';

// select repeat menu to show when a repeat option (e.g. "daily", "weekly") is selected
$.fn.init_repeating = function () {
  $("#select_repeats").change(function () {
    var div_repeats_every_id  = "#repeats_every_" + this.value;
    var div_repeats_on_id     = "#repeats_on_" + this.value;
    var div_repeats_range_id  = "#repeats_range";
    var select_repeats_id     = "#select_repeats_" + this.value;
    // hide *all* repeat every, repeat on, repeat range option
    $(".repeat.every").hide();
    $(".repeat.on").hide();
    $(".repeat.range").hide();
    // show specific repeat every, repeat on, repeat range option
    $(div_repeats_every_id).show();
    $(div_repeats_on_id).show();
    $(div_repeats_range_id).show();
    // empty recurrence text
    $("#recurrence").text("");
    // initialize start date to today
    //$("#range_starts_date").attr("value", (new Date()).zeroTime().asString());
    // send change event to selected option
    $(select_repeats_id).change();
  })

  $("#select_repeats_does_not_repeat").change(function () {
    $current_recurrence_type = 'does_not_repeat';
    // hide range div
    $("#repeats_range").hide();
    // clear recurrence fields
    $("#freq").attr('value', '');
    $("#byday").attr('value', '');
    $("#interval").attr('value', '')
  })
  
  $("#select_repeats_daily").change(function () {
    // set recurrence type and initialize recurrence
    $current_recurrence_type = 'daily';
    $(document).set_daily_recurrence();
  })
  
  $("#select_repeats_weekly").change(function () {
    // set recurrence type and initialize recurrence
    $current_recurrence_type = 'weekly';
    $(document).set_weekly_recurrence();
  })
   
  $("#select_repeats_every_weekday_monday_friday").change(function () {
    // set recurrence type and initialize recurrence
    $current_recurrence_type = 'every_weekday_monday_friday';
    $(document).set_every_weekday_monday_friday_recurrence();
  })
  
  $(".weekly.checkbox.day").click(function () {
    // initialize weekly recurrence using all days selected
    $(document).set_weekly_recurrence();
  })

  $("#range_end_until").click(function () {
    // show date field
    $("#range_end_date").show();
  })

  $("#range_end_never").click(function () {
    // hide date field
    $("#range_end_date").hide();
    // clear date field
    $("#range_end_date").attr("value", '');
    // clear recurrence 'until' field
    $("#until").attr('value', '');
    // update recurrence using end date
    $(document).set_recurrence();
  })
}

$.fn.set_recurrence = function () {
  eval('$(document).' + 'set_' + $current_recurrence_type + '_recurrence();');
}

$.fn.set_daily_recurrence = function () {
  interval = $("#select_repeats_daily option:selected").attr("value");
  
  if (interval == 1) {
    var s = "Daily";
  } else {
    var s = "Every " + interval + " days";
  }
  
  // add end date
  s += $(document).get_recurrence_range_date();
  
  $("#recurrence").text(s);
  
  // set recurrence values
  $("#freq").attr('value', 'daily');
  $("#byday").attr('value', '');
  $("#interval").attr('value', interval);
}

$.fn.set_weekly_recurrence = function () {
  // every 'x' weeks or 'weekly'
  var interval = $("#select_repeats_weekly option:selected").attr("value");
  
  if (interval == 1) {
    var every_weeks = "Weekly";
  } else {
    var every_weeks = "Every " + interval + " weeks";
  }
  
  var days   = new Array();
  var bydays = new Array();
  // on monday, tuesday ...
  $('.checkbox.day:checked').each(function() {
    days.push($(this).attr("name"));
    bydays.push($(this).attr("byday"));
  })
  // build recurrence, e.g. "Every 2 weeks on Monday, Wednesday"
  var s = every_weeks + " on " + days.join(", ");
  
  // add range date
  s += $(document).get_recurrence_range_date();
  
  $("#recurrence").text(s);

  // set recurrence values
  $("#freq").attr('value', 'weekly');
  $("#byday").attr('value', bydays.join(","));
  $("#interval").attr('value', interval);
}

$.fn.set_every_weekday_monday_friday_recurrence = function () {
  var s = "Weekly on Weekdays";
  s += $(document).get_recurrence_range_date();
  $("#recurrence").text(s);

  // set recurrence values
  $("#freq").attr('value', 'weekly');
  $("#byday").attr('value', 'mo,tu,we,th,fr');
  $("#interval").attr('value', '');
}

$.fn.get_recurrence_range_date = function() {
  var s = ''

  if ($("#range_start_date").attr("value")) {
    // start date display looks like 'starting xx/yy/zz'
    s += ", starting " + $("#range_start_date").attr("value");
  }
  
  if ($("#range_end_date").attr("value")) 
  {
    // end date looks like 'until xx/yy/zz' 
    s += ", until " + $("#range_end_date").attr("value");
  }
  return s
}

$.fn.init_datepicker = function () {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+3m'});
}

$.fn.init_timepicker = function() {
  $("#starts_at").timepickr({convention:12});
  $("#ends_at").timepickr({convention:12});
}

$.fn.init_event_form = function() {
  // handle submit event
  $("#add_event_form").submit(function () {
    if (!$("#what").attr('value')) {
      alert("Please specify an event name");
      return false;
    } else {
      // copy 'what' field to 'name
      $("#name").attr('value', $("#what").attr('value'));
    }
    
    if (!$("#when").attr('value')) {
      alert("Please specify an event date");
      return false;
    } else {
      // format 'when' field for 'dstart'
      s = $(document).convert_date_to_string($("#when").attr('value'));
      $("#dstart").attr('value', s);
    }

    if (!$("#starts_at").attr('value')) {
      alert("Please specify an event start time");
      return false;
    } else {
      // format 'starts_at' field for 'tstart'
      s = $(document).convert_time_ampm_to_string($("#starts_at").attr('value'));
      $("#tstart").attr('value', s);
    }

    if (!$("#ends_at").attr('value')) {
      alert("Please specify an event end time");
      return false;
    } else {
      // format 'ends_at' field for 'tend'
      s = $(document).convert_time_ampm_to_string($("#ends_at").attr('value'));
      $("#tend").attr('value', s);
    }
    
    // tend must be later than tstart
    if ($("#tend").attr('value') < $("#tstart").attr('value')) {
      alert("The event end time can not be earlier than the start time");
      return false;
    }
    
    return true;
  })
}

$(document).ready(function() {
  $(document).init_datepicker();
  $(document).init_timepicker();
  $(document).init_repeating();
  $(document).init_event_form();
})
