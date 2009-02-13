$(document).ready(function() {
  var lat = $('#map').attr('lat');
  var lng = $('#map').attr('lng');
  
  $('#map').jmap('init', {'mapType':'map','mapCenter':[lat, lng], 'mapZoom':15});
  $('#map').jmap('AddMarker', {'pointLatLng': [lat, lng]});
  
  $("#add_streetview").click(function() {
    var streetMapCenter = [lat, lng];
    $('#map').jmap('CreateStreetviewPanorama', {'latlng':streetMapCenter});
    return false;
  })
})