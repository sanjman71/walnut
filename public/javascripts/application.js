// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// displays hint text on any input element with the 'title' attribute set
$.fn.init_input_hints = function() {
  var el = $('input[title]');

  // show the display text
  el.each(function(i) {
      $(this).attr('value', $(this).attr('title'));
      $(this).addClass('hint');
  });

  // hook up the blur & focus
  el.focus(function() {
    // clear field on focus if the current value is the hint
    if ($(this).attr('value') == $(this).attr('title'))
    {
      $(this).attr('value', '');
      $(this).removeClass('hint');
    } 
  }).blur(function() {
    // add hint on blur if the field is empty
    if ($(this).attr('value') == '')
    {
      $(this).attr('value', $(this).attr('title'));
      $(this).addClass('hint');
    }
  });
}

$(document).ready(function() {

  $(document).init_input_hints();
  
  $("#search_places_form").submit(function() {
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
})