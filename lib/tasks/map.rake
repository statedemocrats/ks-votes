namespace :map do
  desc 'tasks for the interactive map'
  task setup: :environment do
    # unzip the geojson files
    precincts_geojson = File.join(Rails.root, 'public/kansas-state-voting-precincts-2012-sha-min.geojson.gz')
    precincts_plain = precincts_geojson.gsub('.gz', '')
    system("gunzip -c #{precincts_geojson} > #{precincts_plain}")
  end

  desc 'Apply Geosha tagging to a geojson file'
  task geosha: :environment do
    in_file = ENV['IN_FILE'] or fail "IN_FILE required"
    out_file = ENV['OUT_FILE'] or fail "OUT_FILE required"
    geosha = Geosha.new(geojson: in_file)
    geosha.create_digests
    geosha.write(out_file)
  end

  desc 'dump census tract to json'
  task census_tracts: :environment do
    rep = CensusTractReporter.all_by_year
    File.write('public/all-tracts-by-year.json', rep.to_json)
  end

  desc 'mimic kansas-votes.js data handling to build single .csv'
  task csv: :environment do
    require 'rgeo'
    require 'rgeo/geo_json'
    require 'csv_builder'

    tracts_json = File.join(Rails.root, 'public/all-tracts-by-year.json')
    tracts_geojson = File.join(Rails.root, 'public/kansas-state-voting-precincts-2012-sha-min.geojson')
    builder = CsvBuilder.new(
      elections: JSON.parse(File.read(tracts_json)),
      tracts: RGeo::GeoJSON.decode(File.read(tracts_geojson), json_parser: :json)
    )

    builder.to_csv('public/election-results-combined.csv')
  end
end
