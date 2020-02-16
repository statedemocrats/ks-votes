<!DOCTYPE html>
<html>
<head>
  
  <title>Kansas Map</title>

  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <link rel="stylesheet" type="text/css" href="https://fonts.googleapis.com/css?family=Open+Sans">

  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.2.0/dist/leaflet.css" integrity="sha512-M2wvCLH6DSRazYeZRIm1JnYyh22purTM+FDB5CsyxtQJYeKq83arPe5wgbNmcFXGqiSH2XR8dT/fJISVA1r/zQ==" crossorigin=""/>

  <script src="https://unpkg.com/leaflet@1.2.0/dist/leaflet.js" integrity="sha512-lInM/apFSqyy1o6s89K4iQUKg6ppXEgsVxT35HbzUupEVRh2Eu9Wdl4tHj7dZO0s1uvplcYGmt3498TtHq+log==" crossorigin=""></script>

  <script src="leaflet.ajax.min.js"></script>
  <script src="https://unpkg.com/@mapbox/leaflet-pip@latest/leaflet-pip.js"></script>

  <script src="https://code.jquery.com/jquery-3.2.1.min.js"></script>

  <link rel="stylesheet" href="/assets/main.css">
  <link rel="stylesheet" type="text/css" href="kansas-maps.css">

</head>
<body>

<div id="mask"></div>

<header class="site-header">
<nav class="menu">
 <ul>
  <li><a href="/">Home</a></li>
  <li><a href="./">Maps</a></li>
 </ul>
</nav>

<div id='about'>
</div>

<div id='find'>
 <!-- adjust size based on @media -->
 <input id='precinct' placeholder='Search for shape name' size='60'></input>
 <button id='search'>Search</button>
</div>
</header>

<div id="content">
<div class="map-container">
  <div id='map'></div>
  <div id='details'></div>
</div>
</div>

<footer>
<a href="#" class="active">Kansas Map <?php echo htmlspecialchars($_GET['f']) ?></a>
</footer>

<script>
  var map, geojson, lastPoly, info;
  var style = { weight: 1, opacity: 1, fillOpacity: 0 };
  var polyClick = function(e) {
    var lat = e.latlng ? e.latlng.lat : null;
    var lng = e.latlng ? e.latlng.lng : null;
    var poly = e.target;
    var props = poly.feature.properties;
    $('#details').html(JSON.stringify(props, null, '<br/>') + '<p>[' + lat + ',' + lng + ']</p>');
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

  var geojsonFile = '<?php echo $_GET['f'] ?>';

  geojson = L.geoJson.ajax(geojsonFile, opts);

  var mbAttr = 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
      '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
      'Imagery © <a href="http://mapbox.com">Mapbox</a>',
    mbUrl = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw';

  var grayscale = L.tileLayer(mbUrl, {id: 'mapbox.light', attribution: mbAttr});
  var streets = L.tileLayer(mbUrl, {id: 'mapbox.streets',   attribution: mbAttr});

  var fileParts = geojsonFile.split(/\-/);
  var county = fileParts[0];

  let mapCenters = {
    'johnson': [38.8849,-94.8010],
    'douglas': [38.8829,-95.2692],
    'sedgwick': [37.6887,-97.4580],
    'shawnee': [39.0503,-95.7517],
    'wyandotte': [39.1094,-94.7497]
  };

  map = L.map('map', {
    center: mapCenters[county] || [38.5138, -98.3200],
    zoom: mapCenters[county] ? 10 : 7,
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
    this._div.innerHTML = '<h4>Shape</h4>' +  (props ?  (props.NAME || props.PRECINCT || props.name) : 'Hover over a shape');
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
      var sha = props.geosha || '';
      if (name.match($str) || $str == sha) {
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

