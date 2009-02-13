$(document).ready(function() {
  var lat = $('#map').attr('lat');
  var lng = $('#map').attr('lng');
  var streetMapCenter = [lat, lng];
  
  $('#map').jmap('init', {'mapType':'map','mapCenter':[lat, lng], 'mapZoom':15});
  $('#map').jmap('AddMarker', {'pointLatLng': [lat, lng]});
  // $('#map').jmap('CreateStreetviewPanorama', {'latlng':streetMapCenter});
  
  $("#add_streetview").click(function() {
    $('#map').jmap('CreateStreetviewPanorama', {'latlng':streetMapCenter});
    return false;
  })
})