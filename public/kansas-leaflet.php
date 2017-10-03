<!DOCTYPE html>
<html>
<head>
  
  <title>Kansas Map</title>

  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=Open+Sans">

  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.2.0/dist/leaflet.css" integrity="sha512-M2wvCLH6DSRazYeZRIm1JnYyh22purTM+FDB5CsyxtQJYeKq83arPe5wgbNmcFXGqiSH2XR8dT/fJISVA1r/zQ==" crossorigin=""/>

  <script src="https://unpkg.com/leaflet@1.2.0/dist/leaflet.js" integrity="sha512-lInM/apFSqyy1o6s89K4iQUKg6ppXEgsVxT35HbzUupEVRh2Eu9Wdl4tHj7dZO0s1uvplcYGmt3498TtHq+log==" crossorigin=""></script>

  <script src="https://statedemocrats.us/kansas/map/leaflet.ajax.min.js"></script>
  <script src="https://unpkg.com/@mapbox/leaflet-pip@latest/leaflet-pip.js"></script>

  <script src="https://code.jquery.com/jquery-3.2.1.min.js"></script>

  <link rel="stylesheet" type="text/css" href="kansas-maps.css">

</head>
<body>

<nav class="menu">
 <ul>
  <li><a href="./">Home</a></li>
  <li><a href="maps.php">All Maps</a></li>
 </ul>
</nav>

<div id='about'>
<h1>Kansas Map <?php echo htmlspecialchars($_GET['f']) ?></h1>
</div>

<div id='find'>
 <input id='precinct'></input>
 <button id='search'>Search</button>
</div>
<div id='map'></div>
<div id='details'></div>

<script>
  var map, geojson, lastPoly, info;
  var style = { weight: 1, opacity: 1, fillOpacity: 0 };
  var polyClick = function(e) {
    var poly = e.target;
    var props = poly.feature.properties;
    $('#details').html(JSON.stringify(props, null, '<br/>'));
    poly.setStyle({ weight: 3, color: '#666', fillOpacity: 0.1 });
    if (lastPoly && lastPoly != poly) {
      geojson.resetStyle(lastPoly);
    }
    lastPoly = poly;
  };
  var onHover = function(e) {
    var poly = e.target;
    if (lastPoly != poly) {
      poly.setStyle({ weight: 5, color: '#bbb', fillOpacity: 0.2 });
    }
    info.update(poly.feature.properties);
  };
  var offHover = function(e) {
    var poly = e.target;
    if (lastPoly != poly) {
      geojson.resetStyle(poly);
    }
    info.update();
  };
  var polyEach = function(p, layer) {
    layer.on({
      click: polyClick,
      mouseover: onHover,
      mouseout: offHover
    });
  };
  var opts = { style: style, onEachFeature: polyEach };

  geojson = L.geoJson.ajax('<?php echo $_GET['f'] ?>', opts);

  var mbAttr = 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
      '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
      'Imagery © <a href="http://mapbox.com">Mapbox</a>',
    mbUrl = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw';

  var grayscale = L.tileLayer(mbUrl, {id: 'mapbox.light', attribution: mbAttr});
  var streets = L.tileLayer(mbUrl, {id: 'mapbox.streets',   attribution: mbAttr});

  map = L.map('map', {
    center: [38.5138, -98.3200],
    zoom: 7,
    layers: [grayscale, geojson]
  });

  // control that shows state info on hover
  info = L.control();
  info.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'info');
    this.update();
    return this._div;
  };

  info.update = function (props) {
    this._div.innerHTML = '<h4>Precinct</h4>' +  (props ?  (props.NAME || props.PRECINCT || props.name) : 'Hover over a precinct');
  };

  info.addTo(map);

  // search by precinct name
  $('#search').on('click', function(e) {
    var $str = $('#precinct').val();
    if ($str.length == 0) return;

    //console.log($str);
    var found = false;
    geojson.eachLayer(function(layer) {
      if (found) return;
      var props = layer.feature.properties;
      var name = (props.NAME || props.PRECINCT || props.name);
      if (name.match($str)) {
        //console.log(layer);
        layer.fireEvent('click');
        map.fitBounds(layer.getLatLngs());
        found = true;
      }
    });
  });
  // enter key listener
  $("#precinct").keyup( function(e) {
    if (e.keyCode == 13) {
      $('#search').click();
    }
  });
</script>

</body>
</html>

