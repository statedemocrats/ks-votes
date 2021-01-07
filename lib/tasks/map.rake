namespace :map do
  desc 'tasks for the interactive map'
  task setup: :environment do
    # unzip the geojson files
    precincts_geojson = File.join(Rails.root, 'public/kansas-state-voting-precincts-2012-sha-min.geojson.gz')
    precincts_plain = precincts_geojson.gsub('.gz', '')
    system("gunzip -c #{precincts_geojson} > #{precincts_plain}")
    precincts_2020 = File.join(Rails.root, "public/PVS_19_v2-kansas-sha-min.geojson.gz")
    system("gunzip -c #{precincts_2020} > #{precincts_2020.gsub('.gz', '')}")
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
    require 'csv_builder'

    puts "Reading .json"
    tracts_json = File.join(Rails.root, 'public/all-tracts-by-year.json')
    tracts_geojson = File.join(Rails.root, 'public/kansas-state-voting-precincts-2012-sha-min.geojson')
    builder = CsvBuilder.new(
      elections: JSON.parse(File.read(tracts_json)),
      tracts: JSON.parse(File.read(tracts_geojson)),
      counties: Hash[County.all.map { |c| [c.fips, c.name] }],
    )

    puts "Writing .csv"
    csvfile = 'public/election-results-combined.csv'
    rows = builder.to_csv(csvfile)
    puts "Wrote #{rows} rows, #{builder.header.size} columns to #{csvfile}"
  end
end
