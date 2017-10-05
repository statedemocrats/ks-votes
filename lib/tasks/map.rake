namespace :map do
  desc 'tasks for the interactive map'
  task setup: :environment do
    # unzip the geojson files
    precincts_geojson = File.join(Rails.root, 'public/kansas-state-voting-precincts-2012-sha-min.geojson.gz')
    precincts_plain = precincts_geojson.gsub('.gz', '')
    system("gunzip -c #{precincts_geojson} > #{precincts_plain}")
  end
end
