<?php

/* for a given lat/lng pair, return array of the relevant political districts.

  * State Board of Education
  * District Court
  * State House
  * State Senate
  * Congressional

*/

header('Content-Type: application/json');

$lat = isset($_GET['lat']) ? $_GET['lat'] : null;
$lng = isset($_GET['lng']) ? $_GET['lng'] : null;

if (!$lat || !$lng) {
  header('X-districts: missing lat or lng param', 400);
  print json_encode(array('error' => 'missing lat or lng param'));
  exit(0);
}

require 'pointLocation.php';

$geo_files = array(
  'hd' => 'cb_2016_20_sldl_500k.geojson',
  'sd' => 'cb_2016_20_sldu_500k.geojson',
  'cd' => 'KS_Cong_2012.geojson',
  'sbe' => 'Ks_SBOE_2012.geojson',
  'c' => 'ks-counties.geojson',
);

$property_keys = array(
  'cb_2016_20_sldl_500k.geojson' => 'NAME',
  'cb_2016_20_sldu_500k.geojson' => 'NAME',
  'KS_Cong_2012.geojson' => 'DISTRICT',
  'Ks_SBOE_2012.geojson' => 'DISTRICT',
  'ks-counties.geojson' => 'NAME',
);

$district_courts = array(
  1  => array("Atchison", "Leavenworth"),
  2  => array("Jackson", "Jefferson", "Pottawatomie", "Wabaunsee"),
  3  => array("Shawnee"),
  4  => array("Anderson", "Coffey", "Franklin", "Osage"),
  5  => array("Chase", "Lyon"),
  6  => array("Bourbon", "Linn", "Miami"),
  7  => array("Douglas"),
  8  => array("Dickinson", "Geary", "Marion", "Morris"),
  9  => array("Harvey", "McPherson"),
  10 => array("Johnson"),
  11 => array("Cherokee", "Crawford", "Labette"),
  12 => array("Cloud", "Jewell", "Lincoln", "Mitchell", "Republic", "Washington", ),
  13 => array("Butler", "Elk", "Greenwood"),
  14 => array("Chautauqua", "Montgomery"),
  15 => array("Cheyenne", "Logan", "Rawlins", "Sheridan", "Sherman", "Thomas", "Wallace", ),
  16 => array("Clark", "Comanche", "Ford", "Gray", "Kiowa", "Meade"),
  17 => array("Decatur", "Graham", "Norton", "Osborne", "Phillips", "Smith"),
  18 => array("Sedgwick"),
  19 => array("Cowley"),
  20 => array("Barton", "Ellsworth", "Rice", "Russell", "Stafford"),
  21 => array("Clay", "Riley"),
  22 => array("Brown", "Doniphan"),
  23 => array("Ellis", "Gove", "Rooks", "Trego"),
  24 => array("Edwards", "Hodgeman", "Lane", "Ness", "Pawnee", "Rush"),
  25 => array("Finney", "Greeley", "Hamilton", "Kearny", "Scott", "Wichita"),
  26 => array("Grant", "Haskell", "Morton", "Seward", "Stanton", "Stevens"),
  27 => array("Reno"),
  28 => array("Ottawa", "Saline"),
  29 => array("Wyandotte"),
  30 => array("Barber", "Harper", "Kingman", "Pratt", "Sumner"),
  31 => array("Allen", "Neosho", "Wilson", "Woodson"),
);

$point = "$lat $lng";
$result = array();

foreach($geo_files as $key => $file) {
  $property = $property_keys[$file];
  $geo = json_decode(file_get_contents($file), true);
  $pointLocation = new pointLocation();

  foreach($geo['features'] as $feature) {
    $id = $feature['properties'][$property];
    $coords = $feature['geometry']['coordinates'][0];
    $polygon = array();
    foreach($coords as $pair) {
      $polygon[] = "$pair[1] $pair[0]";
    }

    //error_log("$key $file $id looking for '$point' in " . var_export($polygon, true));

    $r = $pointLocation->pointInPolygon($point, $polygon);

    if ($r == 'inside' || $r == 'boundary' || $r == 'vertex') {
      $result[$key] = $id;
      break;
    }
  }
}

foreach($district_courts as $district => $counties) {
  if (in_array($result['c'], $counties)) {
    $result['dc'] = $district;
    break;
  }
}

header('X-districts: success', 200);
print json_encode($result);
exit(0);

?>
