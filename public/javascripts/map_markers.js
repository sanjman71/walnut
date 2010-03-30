$(document).ready(function() {
  var bounds = new GLatLngBounds();
  var markers = [];
  var baseIcon;
  var gmap;
  var zoom = 0;
  
  $('div#map').jmap('init', {'mapType':'map','mapCenter':[0, 0], 'mapZoom':12 },
    function (map, element, options) {
      // remember the map
      gmap = map;
      // Create the base icon
      createBaseIcon();
      var lat, lng;
      $('.mappable').each(function(i, latlng)
        {
          lat = latlng.attributes["lat"].nodeValue;
          lng = latlng.attributes["lng"].nodeValue;
          color = latlng.attributes["color"].nodeValue;
          glatlng = new GLatLng(lat, lng);
          html = latlng.attributes["html"].nodeValue;
          index = parseInt(latlng.attributes["index"].nodeValue);
          zoom = parseInt(latlng.attributes["zoom"].nodeValue);
          markers[index] = createMarker(glatlng, html, index, color);
          map.addOverlay(markers[index]);
          bounds.extend(glatlng);
        }
      );
      if (zoom == 0) {
        // set zoom using bounds
        map.setZoom(map.getBoundsZoomLevel(bounds)-1);
      } else {
        // set zoom using configured value
        map.setZoom(zoom);
      }
      map.setCenter(bounds.getCenter());
    })

    $("div.mappable").click(function() {
      gmap.panTo(markers[$(this).attr("index")].getLatLng());
      markers[$(this).attr("index")].openInfoWindowHtml($(this).attr("html"));
      $(".mappable.selected").removeClass("selected").addClass("unselected");
      $(this).addClass("selected").removeClass("unselected");
    })
})

function createBaseIcon()
{
  baseIcon = new GIcon(G_DEFAULT_ICON);
  baseIcon.shadow = "http://www.google.com/mapfiles/shadow50.png";
  baseIcon.iconSize = new GSize(20, 34);
  baseIcon.shadowSize = new GSize(37, 34);
  baseIcon.iconAnchor = new GPoint(9, 34);
  baseIcon.infoWindowAnchor = new GPoint(9, 2);
}

function setSelected(index)
{
  $(".mappable.selected").removeClass("selected").addClass("unselected");
  $("#mappable_" + index).addClass("selected").removeClass("unselected");
}

function createMarker(glatlng, html, index, color) {
  // Create a lettered icon for this point using our icon class
  var letter          = String.fromCharCode("A".charCodeAt(0) + index);
  var letteredIcon    = new GIcon(baseIcon);
  letteredIcon.image  = google_marker(color, letter);

  // Set up our GMarkerOptions object
  markerOptions = { icon:letteredIcon, clickable: true };

  var marker = new GMarker(glatlng, markerOptions);
  marker.bindInfoWindowHtml(html)

  GEvent.addListener(marker, "click", function() {
    setSelected(index);
  });
  return marker;
}

function google_marker(color, letter) {
  return google_marker_remote_path(color, letter);
}

function google_marker_local_path(color, letter) {
  return "/images/marker" + color + letter + ".png";
}

function google_marker_remote_path(color, letter) {
  var s = "http://www.google.com/mapfiles/marker";
  if (color != '') {
    // use color and letter
    return s + color + letter + ".png";
  } else {
    // use defaut color, no letter
    return s + ".png";
  }
}
