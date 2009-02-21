$(document).ready(function() {
  
  $(".remove.tag").click(function() {
    var id = $(this).attr("id");
    var tag_id = "tag_" + id;
    var tag = $("#" + tag_id).text();
        
    // add tag to remove tags list
    var remove_tags = $("#remove_tags").attr("value");
    
    if (remove_tags != ''){
      // add comma separator
      remove_tags = remove_tags + ","
    }
    remove_tags = remove_tags + tag
    $("#remove_tags").attr("value", remove_tags);
    
    // mark tag as deleted
    $("#" + tag_id).wrap("<del></del>");
    
    // hide remove link
    $(this).addClass('hide');
    
    return false;
  })
  
  $("#add_tag").click(function() {
    var new_tag = $("#new_tag").attr("value");
    
    if (new_tag == '') {
      alert("please enter a tag");
      return false;
    }

    // build list, and add new tag
    var cur_add_list = $("#add_list").text();
    
    if (cur_add_list == '') {
      // current add list is empty
      var add_list = []
    } else {
      // current add list is not empty
      var add_list = cur_add_list.split(", ");
    }
    
    add_list.push(new_tag);
    
    $("#add_list").text(add_list.join(", "));
    $("#add_container").css('visibility', 'visible');
    $("#new_tag").attr("value", '');
    
    return false;
  })
  
  $("#update_tag_group").click(function() {
    // fill in add_tags from add list
    $("#add_tags").attr("value", $("#add_list").text());
    
    // remove_tags should already be populated
    
    // disable button
    $("#update_tag_group").attr("disabled", "disabled");
    
    // do the normal submit
    return true;
  })
})
