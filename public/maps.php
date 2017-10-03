<html>
<head>
  <title>Kansas Maps</title>

  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=Open+Sans">
  <link rel="stylesheet" type="text/css" href="kansas-maps.css">

</head>
<body>

<h2>Kansas Maps</h2>
<ul>
 <li><a href="kansas-votes.html">Combined 2012 County, Legislative, Precinct</a></li>

<?php
$files = scandir($_SERVER['DOCUMENT_ROOT']);
$geojson_files = preg_grep('/^.+-county-precincts-.+\.geojson$/', $files);
//print_r($geojson_files);
foreach ($geojson_files as $f) {
  echo "<li><a href='kansas-leaflet.php?f=$f'>$f</a></li>";
}
?>

</ul>

</body>
</html>
