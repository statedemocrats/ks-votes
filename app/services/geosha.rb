require 'digest'
require 'rgeo/geo_json'

# manually trim all coordinates to the same level of precision.
# because precision varies and precincts might move a block or two
# in one direction or another, or geojson files may have varying degrees of precision.
# according to
# https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude/8674#8674
# 2 decimal places gets us within 1.1km (1100 meters) which is about 3/4 of a mile.
# 1 decimal place gets us within 11.1km which is about 7 miles.
# The assumption here is that the *combination* of coordinates at that level of precision
# is unique enough and accurate enough to locate exactly one precinct.

class RGeo::GeoJSON::Feature
  def outline
    geometry.envelope.as_text.gsub(/\.(\d\d)\d+/, '.\1')
  end
end

# this class adds a 'geosha' property to each Feature in a GeoJSON file
# so that the geometry can be matched across files, regardless of which
# other properties might be present in files. This is particularly helpful
# (we hope) when precincts change names but not dimensions.
class Geosha
  def self.kansas2012
    new(geojson: 'public/kansas-state-voting-precincts-2012-sha-min.geojson')
  end

  def initialize(geojson:)
    @geojson = RGeo::GeoJSON.decode(File.read(geojson), json_parser: :json)
  end

  def create_digests
    features.each do |feature|
      sha = Digest::SHA256.hexdigest(feature.outline)
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

  def contains_dupe_shas?
    shas = {}
    features.each do |f|
      sha = f['geosha']
      if shas[sha]
        return features_for_property('geosha', sha)
      end
      shas[sha] = true
    end
    false
  end

  def feature_for_sha(sha)
    features_for_property('geosha', sha).first
  end

  def features_for_property(propname, propval)
    features.select {|f| f[propname] == propval }
  end
end
