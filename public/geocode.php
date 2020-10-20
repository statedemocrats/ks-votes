<?php
  define('CACHE_TTL', 86400); // 24 hours
  $address = $_GET['address'];
  if (!$address) {
    header('X-geocode: address required', 400, false);
    print 'address required';
    exit(0);
  }

  header('Content-Type: application/json');

  require 'FileCache.php';
  $cache = new FileCache();
  $key = sha1($address);
  $json = $cache->get($key);
  if (!$json) {
    $json = fetch_geocode($key, $address);
  }
  print $json;

  function fetch_geocode($key, $address) {
    $base_url = 'https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?benchmark=9&format=json&address=';
    $opts = array(
      'http' => array(
        'method' => 'GET',
        'header' => "User-Agent: statedems/1.0\r\nAccept: application/json\r\n",
      ),
      'ssl' => array('verify_peer' => false, 'verify_peer_name' => false )
    );
    $context = stream_context_create($opts);
    $url = $base_url . urlencode($address);
    $json = file_get_contents($url, false, $context);
    if ($json) {
      $cache = new FileCache();
      $cache->save($key, $json, CACHE_TTL);
    }
    return $json;
  }
?>
