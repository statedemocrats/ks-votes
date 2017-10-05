require 'digest'
require 'rgeo/geo_json'

class Geosha
  def initialize(geojson:)
    @geojson = RGeo::GeoJSON.decode(File.read(geojson), json_parser: :json)
  end

  def create_digests
    features.each do |feature|
      # manually trim all coordinates to 2nd decimal point.
      # NOTE this assumes all coordinates are at least that long.
      # this is because precision varies and precincts might move a block or two
      # in one direction or another.
      # according to
      # https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude/8674#8674
      # 2 decimal places gets us within 1.1km (1100 meters) which is about 3/4 of a mile.
      # the assumption here is that the *combination* of coordinates at that level of precision
      # is unique enough and accurate enough to locate exactly one precinct.
      outline = feature.geometry.envelope.as_text.gsub(/\.(\d\d)\d+/, '.\1')
      sha = Digest::SHA256.hexdigest(outline)
      props = feature.instance_variable_get(:@properties)
      props['geosha'] = sha
    end
    features.length
  end

  def write(path)
    j = RGeo::GeoJSON.encode(@geojson).to_json
    File.write(path, j)
  end

  def features
    @geojson.entries
  end

  def feature_for_sha(sha)
    features_for_property('geosha', sha).first
  end

  def features_for_property(propname, propval)
    features.select {|f| f[propname] == propval }
  end
end
