// KS Votes JS
var map, counties, state_leg_lower, state_leg_upper, precincts, info;
var lastCounty, lastSenate, lastHouse, lastPrecinct, lastPoly;
var style = { weight: 1, opacity: 1, fillOpacity: 0 };
var renderPolys = function(polys) {
  //console.log('clicked on', polys);
  $.each(polys, function(idx, poly) {
    if (!poly) {
      console.log("No poly for idx", idx);
      return true;
    }
    var props = poly.feature.properties;
    //console.log(props);
    if (props['LSAD'] && props['LSAD'] == 'County') {
      $('#county').html('<h3>County</h3>' + props['NAME'] + ' [' + props['COUNTY'] + ']');
      //map.fitBounds(poly.getBounds());
      poly.setStyle({ weight: 3, color: '#666', fillOpacity: 0.1 });
      if (lastCounty && lastCounty != poly) {
        counties.resetStyle(lastCounty);
      }
      lastCounty = poly;
      if (lastPoly && lastPoly != poly) {
        counties.resetStyle(lastPoly);
      }
      lastPoly = poly;
    }
    if (props['SLDLST']) {
      $('#house').html('<h3>House District</h3>' + props['NAME']);
      poly.setStyle({ weight: 3, color: 'green', fillOpacity: 0.1 });
      if (lastHouse && lastHouse != poly) {
        state_leg_lower.resetStyle(lastHouse);
      }
      lastHouse = poly;
    }
    if (props['SLDUST']) {
      $('#senate').html('<h3>Senate District</h3>' + props['NAME']);
      poly.setStyle({ weight: 3, color: '#ffc300', fillOpacity: 0.1 });
      if (lastSenate && lastSenate != poly) {
        state_leg_upper.resetStyle(lastSenate);
      }
      lastSenate = poly;
    }
    if (props['VTDNAME']) {
      $('#precinct').html('<h3>Precinct</h3>' + props['VTDNAME'] + ' [' + props['VTD_S'] + ']');
      $('#precinct').append(JSON.stringify(props, null, '<br/>'));
      poly.setStyle({ weight: 3, color: '#222' });
      if (lastPrecinct && lastPrecinct != poly) {
        precincts.resetStyle(lastPrecinct);
      }
      lastPrecinct = poly;
    }
  });
};
var polyClick = function(e) {
  var lng = e.latlng.lng;
  var lat = e.latlng.lat;
  var polys_clicked = [];
  var pip_counties = leafletPip.pointInLayer([lng,lat], counties);
  var pip_lower = leafletPip.pointInLayer([lng,lat], state_leg_lower);
  var pip_upper = leafletPip.pointInLayer([lng,lat], state_leg_upper);
  var pip_precincts = leafletPip.pointInLayer([lng,lat], precincts);
  if (map.hasLayer(counties)) {
    polys_clicked.push(pip_counties[0]);
  }
  if (map.hasLayer(state_leg_lower)) {
    polys_clicked.push(pip_lower[0]);
  }
  if (map.hasLayer(state_leg_upper)) {
    polys_clicked.push(pip_upper[0]);
  }
  if (map.hasLayer(precincts)) {
    polys_clicked.push(pip_precincts[0]);
  }
  renderPolys(polys_clicked);
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
    counties.resetStyle(poly);
  }
  info.update();
};
var countyEach = function(p, layer) {
  layer.on({
    mouseover: onHover,
    mouseout: offHover,
    click: polyClick
  });
};
var polyEach = function(p, layer) {
  layer.on({click: polyClick});
};
var opts = { style: style, onEachFeature: polyEach };

// load election results first so they are available when we render precincts
var elections, legend, president2016;
$.getJSON('all-precincts-by-year.json', function(data) {
  elections = data;
  legend = elections['legend'];
  var presId, g2016Id;
  $.each(legend['races']['offices'], function(key, val) {
    if (val['n'] == 'President') {
      presId = key;
      return false;
    }
  });
  $.each(legend['races']['elections'], function(key, val) {
    if (val == '2016 general') {
      g2016Id = key;
      return false;
    }
  });
  president2016 = [g2016Id, presId].join(':');
});

var colors = {
  'solid_r': '#ff0000',
  'light_r': '#ff8c8c',
  'solid_d': '#0055ff',
  'light_b': '#8cb2ff',
  'purple' : '#c242f4',
  'unknown': '#f4e242',
};

var getPrecinctColor = function(feature) {
  var unknown = colors['unknown'];
  var vtd = feature.properties['VTD_2012'];
  //console.log('vtd', vtd, president2016);
  var precinct_history = elections[vtd];
  if (!precinct_history) {
    return unknown;
  }
  //console.log('pres2016', precinct_history);
  var results = precinct_history[president2016];
  //console.log(results);
  var color = 'solid_r';
  if (!results || !results['m'] || !results['w']) {
    return unknown;
  }
  var winner = results['w'];
  var margin = results['m'];
  if (margin < 10) {
    if (winner == 'r') {
      color = 'light_r';
    }
    else if (winner == 'd') {
      color = 'light_b';
    }
    else {
      color = 'purple';
    }
  }
  else if (winner == 'r') {
    color = 'solid_r';
  }
  else if (winner == 'd') {
    color = 'solid_d';
  }
  else {
    color = 'unknown';
  }
  return colors[color];
};

counties = L.geoJson.ajax('ks-counties.geojson', { style: style, onEachFeature: countyEach });
state_leg_lower = L.geoJson.ajax('cb_2016_20_sldl_500k.geojson', opts);
state_leg_upper = L.geoJson.ajax('cb_2016_20_sldu_500k.geojson', opts);
precincts = L.geoJson.ajax('kansas-state-voting-precincts-2012-sha-min.geojson', {
  onEachFeature: polyEach,
  style: function(feature) {
    return {
      color: '#777',
      weight: 1,
      opacity: 1,
      fillOpacity: 0.3,
      fillColor: getPrecinctColor(feature)
    };
  }
});

var mbAttr = 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
    '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
    'Imagery © <a href="http://mapbox.com">Mapbox</a>',
  mbUrl = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw';

var grayscale = L.tileLayer(mbUrl, {id: 'mapbox.light', attribution: mbAttr});
var streets = L.tileLayer(mbUrl, {id: 'mapbox.streets',   attribution: mbAttr});

map = L.map('map', {
  center: [38.5138, -98.3200],
  zoom: 6,
  layers: [grayscale, counties]
});

var baseLayers = {
  "Grayscale": grayscale,
  "Streets": streets
};

var overlays = {
  "Counties": counties,
  "2016 State Senate": state_leg_upper,
  "2016 State House": state_leg_lower,
  "2012 Precincts": precincts
};

L.control.layers(baseLayers, overlays).addTo(map);

// control that shows state info on hover
info = L.control();
info.onAdd = function (map) {
  this._div = L.DomUtil.create('div', 'info');
  this.update();
  return this._div;
};

info.update = function (props) {
  this._div.innerHTML = (props ?  (props.NAME || props.PRECINCT || props.name) : 'Hover over a county');
};

info.addTo(map);

// search by precinct name
$('#search').on('click', function(e) {
  var $str = $('#iprecinct').val();
  if ($str.length == 0) return;

  if (!map.hasLayer(precincts)) {
    alert("You must select a Precinct layer from the control box in the upper right corner");
    return;
  }

  //console.log($str);
  var found = false;
  precincts.eachLayer(function(layer) {
    if (found) return;
    var props = layer.feature.properties;
    var name = (props.VTDNAME || props.NAME || props.PRECINCT || props.name || props.geosha);
    var sha = props.geosha || '';
    if (name.match($str) || sha.match($str)) {
      //console.log(layer);
      renderPolys([layer]);
      //layer.fireEvent('click');
      map.fitBounds(layer.getLatLngs());
      found = true;
    }
  });
});
// enter key listener
$("#iprecinct").keyup( function(e) {
  if (e.keyCode == 13) {
    $('#search').click();
  }
});