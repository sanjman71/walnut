// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// displays hint text on any input element with the 'title' attribute set
$.fn.init_input_hints = function () {
  var el = $('input[title]');

  // show the display text
  el.each(function(i) {
      $(this).attr('value', $(this).attr('title'));
  });

  // hook up the blur & focus
  el.focus(function() {
    // clear field on focus if the current value is the hint 
    if ($(this).attr('value') == $(this).attr('title'))
    {
      $(this).attr('value', '');
    }
  }).blur(function() {
      // add hint on blur if the field is empty
      if ($(this).attr('value') == '')
      {
        $(this).attr('value', $(this).attr('title'));
      }
  });
}

$(document).ready(function() {

  $(document).init_input_hints();
})