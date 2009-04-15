// recommend a location
$.fn.init_recommend_location = function() {
  $("#recommend_location").click(function() {
    $.post(this.href, {}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_recommend_location();
})