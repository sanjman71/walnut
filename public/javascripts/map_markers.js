$(document).ready(function() {
  var bounds = new GLatLngBounds();
  var markers = [];
  var baseIcon;
  var gmap;
  $(document).ready(function(){
    $('#map').jmap('init', {'mapType':'map','mapCenter':[0, 0], 'mapZoom':12 },
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
            markers[i] = createMarker(glatlng, html, i, color);
            map.addOverlay(markers[i]);
            bounds.extend(glatlng);
          }
        );
        map.setZoom(map.getBoundsZoomLevel(bounds)-1);
        map.setCenter(bounds.getCenter());
      }
    );
    $(".mappable").click(function(){
      gmap.panTo(markers[$(this).attr("index")].getLatLng());
      markers[$(this).attr("index")].openInfoWindowHtml($(this).attr("html"));
      $(".mappable.selected").removeClass("selected").addClass("unselected");
      $(this).addClass("selected").removeClass("unselected");
    });
  })
});

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
  var letter = String.fromCharCode("A".charCodeAt(0) + index);
  var letteredIcon = new GIcon(baseIcon);
  letteredIcon.image = "http://www.google.com/mapfiles/marker" + color + letter + ".png";

  // Set up our GMarkerOptions object
  markerOptions = { icon:letteredIcon, clickable: true };

  var marker = new GMarker(glatlng, markerOptions);
  marker.bindInfoWindowHtml(html)

  GEvent.addListener(marker, "click", function() {
    setSelected(index);
  });
  return marker;
}
