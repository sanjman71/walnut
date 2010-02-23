// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.ajaxSetup({
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
})

// prevent a method from being called too often, e.g. live search requests
Function.prototype.sleep = function (millisecond_delay) {
  if(window.sleep_delay != undefined) clearTimeout(window.sleep_delay);
  var function_object = this;
  window.sleep_delay  = setTimeout(function_object, millisecond_delay);
};

// displays hint text on any input element with the 'title' attribute set
$.fn.init_input_hints = function() {
  var el = $('input[title]');
  
  // show the display text
  el.each(function(i) {
    if ($(this).attr('value') == '') {
      // add hint if the value is initially empty
      $(this).attr('value', $(this).attr('title'));
      $(this).addClass('hint');

      // hide clear button
      $clear = $(this).parent().next(".clear");
      $clear.hide();
    }
  });

  // hook up the blur & focus
  el.focus(function() {
    if ($(this).attr('value') == $(this).attr('title'))
    {
      // clear field on focus if the current value is the hint
      $(this).attr('value', '');
      $(this).removeClass('hint');
    }
  }).blur(function() {
    // check field value on blur
    $clear = $(this).parent().next(".clear");
    if ($(this).attr('value') == '')
    {
      // add hint if the field is empty
      $(this).attr('value', $(this).attr('title'));
      $(this).addClass('hint');
      // hide clear button
      $clear.hide();
    } else {
      // show clear button
      $clear.show();
    }
  });
  
  // hook up the clear buttons
  /*
  $("span.clear").click(function() {
    //console.log("clear field");

    // clear the input field
    $field = $(this).prev(".text").find("input.title");
    $field.attr('value', '');

    // set the focus
    $field.focus();

    // hide the button
    $(this).hide();
  });
  */
}

$.fn.init_search_objects_form = function() {
  /*
  // show hidden search places form onclick
  $("#search_link").click(function () {
    $("#search_places").css('visibility', 'visible');
    return false;
  })
  */
  
  $("input:checkbox#search_locations, input:checkbox#search_events").click(function() {
    if (this.checked) {
      // uncheck all other check boxes
      var $checkbox = this;
      $("input:checkbox.search_klass").each(function() {
        if (this != $checkbox) {
          $(this).attr("checked", false);
        }
      })
    }
  })

  $("#search_objects_form").submit(function() {
    // check field values
    var $search_what  = $(this).find("#search_what")
    var $search_where = $(this).find("#search_where")
    var search_errors = 0;
    
    if ($search_what.attr("value") == $search_what.attr("title")) 
    {
      // highlight the field
      $search_what.addClass("highlight");
      search_errors += 1
    } 
    else 
    {
      $search_what.removeClass("highlight");
    }

    if ($search_where.attr("value") == $search_where.attr("title")) 
    {
      // highlight the field
      $search_where.addClass("highlight");
      search_errors += 1
    } 
    else 
    {
      $search_where.removeClass("highlight");
    }

    if (search_errors > 0) 
    {
      return false;
    }
    
    return true;
  })
}

$.fn.init_autocomplete_search_where = function() {
  // init autocomplete field with where data
  $("#search_where").autocomplete('/autocomplete/search/where', {matchContains:false, minChars:1, max:50});
}

// convert mm/dd/yyyy date to yyyymmdd string
$.fn.convert_date_to_string = function(s) {
  re    = /(\d{2,2})\/(\d{2,2})\/(\d{4,4})/
  match = s.match(re);
  s     = match[3] + match[1] + match[2]
  return s
}

// convert '03:00 pm' time format to 'hhmmss' 24 hour time format
$.fn.convert_time_ampm_to_string = function(s) {
  re      = /(\d{2,2}):(\d{2,2}) (am|pm)/
  match   = s.match(re);

  // convert hour to integer, leave minute as string
  hour    = parseInt(match[1], 10); 
  minute  = match[2];

  if (match[3] == 'pm') {
    // add 12 for pm
    hour += 12;
  }

  value = hour < 10 ? "0" + hour.toString() : hour.toString()
  value += minute + "00";
  return value
}

$(document).ready(function() {
  $(document).init_input_hints();
  $(document).init_search_objects_form();
  $(document).init_autocomplete_search_where();
})