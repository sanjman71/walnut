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
    $("#range_starts_date").attr("value", (new Date()).zeroTime().asString());
    // send change event to selected option
    $(select_repeats_id).change();
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

  $("#range_ends_until").click(function () {
    // show date field
    $("#range_ends_date").show();
  })

  $("#range_ends_never").click(function () {
    // hide date field
    $("#range_ends_date").hide();
    // clear date field
    $("#range_ends_date").attr("value", '');
    // update recurrence using end date
    $(document).set_recurrence();
  })
}

$.fn.set_recurrence = function () {
  eval('$(document).' + 'set_' + $current_recurrence_type + '_recurrence();');
}

$.fn.set_daily_recurrence = function () {
  days = $("#select_repeats_daily option:selected").attr("value");
  
  if (days == 1) {
    var recurrence = "Daily";
  } else {
    var recurrence = "Every " + days + " days";
  }
  
  // add end date
  recurrence += $(document).get_recurrence_range_end_date();
  
  $("#recurrence").text(recurrence);
}

$.fn.set_weekly_recurrence = function () {
  // every 'x' weeks or 'weekly'
  var weeks = $("#select_repeats_weekly option:selected").attr("value");
  
  if (weeks == 1) {
    var every_weeks = "Weekly";
  } else {
    var every_weeks = "Every " + weeks + " weeks";
  }
  
  var days = new Array();
  // on monday, tuesday ...
  $('.checkbox.day:checked').each(function() {
    days.push($(this).attr("name"));
  })
  // build recurrence, e.g. "Every 2 weeks on Monday, Wednesday"
  var recurrence = every_weeks + " on " + days.join(", ");
  
  // add end date
  recurrence += $(document).get_recurrence_range_end_date();
  $("#recurrence").text(recurrence);
}

$.fn.set_every_weekday_monday_friday_recurrence = function () {
  var recurrence = "Weekly on Weekdays";
  recurrence += $(document).get_recurrence_range_end_date();
  $("#recurrence").text(recurrence);
}

$.fn.get_recurrence_range_end_date = function() {
  var end_date = $("#range_ends_date").attr("value");
  var s = ''
  if (end_date) 
  {
    // end date looks like 'until xx/yy/zz' 
    s += ", until " + end_date;
  }
  return s
}

$.fn.init_datepicker = function(s) {
  var defaults = {start_date : "07/01/2009", end_date : "12/31/2009", max_days : 7}
  s = $.extend({}, defaults, s);
  
  // initialize date picker object
  $('.date-pick').datePicker({clickInput:true, createButton:false, startDate:s.start_date, endDate:s.end_date});

  // bind to end date selected event
  $('#range_ends_date').bind(
    'dpClosed',
    function(e, selectedDates)
    {
      // update recurrence
      $(document).set_recurrence();
    }
  )
}

$(document).ready(function() {
  Date.firstDayOfWeek = 7;
  Date.format = 'mm/dd/yyyy';
  $(document).init_datepicker({start_date : (new Date()).addDays(1).asString(), end_date : (new Date()).addMonths(3).asString(), max_days:10});

  $(document).init_repeating();
})
