<html>
<head>
  <title>Kansas Maps</title>

  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <link rel="stylesheet" type="text/css" href="https://fonts.googleapis.com/css?family=Open+Sans">
  <link rel="stylesheet" href="/assets/main.css">
  <link rel="stylesheet" type="text/css" href="kansas-maps.css">

</head>
<body>

<header class="site-header">
<nav class="menu">
 <ul>
  <li><a href="/">Home</a></li>
  <li class="active"><a href="#" class="active">Kansas Maps</a></li>
 </ul>
</nav>
</header>

<ul>
 <li><a href="kansas-votes.html">Combined 2012 County, Legislative, Precinct</a></li>

<?php

function list_geojson_files($dirname) {
  $files = scandir($dirname);
  $geojson_files = preg_grep('/^.+\.geojson$/', $files);
  $server_root = dirname($_SERVER['SCRIPT_FILENAME']);
  $basename = basename($dirname);
  $prefix = '';
  if ($server_root != $dirname) {
    $prefix = "$basename/";
  }
  foreach ($geojson_files as $f) {
    echo "<li><a href='kansas-leaflet.php?f=$prefix$f'>$f</a></li>";
  }
}

list_geojson_files(dirname($_SERVER['SCRIPT_FILENAME']));
list_geojson_files(dirname($_SERVER['SCRIPT_FILENAME']) . '/PVS_19_v2/');
?>

</ul>

</body>
</html>
