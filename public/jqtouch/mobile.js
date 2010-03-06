var jQT = new $.jQTouch({cacheGetRequests: false, statusBar: 'black'});


$.fn.init_search_submit = function() {
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

$.fn.init_login_submit = function() {
  $("form#login_form").submit(function() {
    // post request and handle the response
    $.ajax({
      type: $(this).attr('method'),
      url: $(this).attr('action'),
      dataType: 'json',
      data: $(this).serialize(),
      complete: function(req) {
        if (req.status == 200) {
          jQT.goBack();
        } else {
          alert("There was an error logging in. Try again.");
        }
      }
    });
    
    return false;
  })
}

$.fn.init_search_city = function() {
  $("a#search_city").bind('tap click', function() {
    $("form#search_form input#search_where").val($(this).text());
    return true;
  })
}

$(document).ready(function() {
  $(document).init_login_submit();
  $(document).init_search_submit();
  $(document).init_search_city();
})
