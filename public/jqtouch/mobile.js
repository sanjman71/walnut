var jQT = new $.jQTouch({cacheGetRequests: false, statusBar: 'black'});


$.fn.init_search_submit = function() {
  // init autocomplete field with where data
  $("form#search_form").submit(function() {
    var what  = $(this).find("input#search_what").val();
    var where = $(this).find("input#search_where").val();

    if (what == '') { 
      alert("Please enter something to search for");
      return false;
    }

    if (where == '') { 
      alert("Please enter a city, zip or neighborhood");
      return false;
    }

    return true;
  })
}

$(document).ready(function() {
  $(document).init_search_submit();
})
