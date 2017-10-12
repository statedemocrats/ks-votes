namespace :match do
  task sedgwick: :environment do
    @geo_finder = GeoFinder.new

    # load sedgwick geosha
    geosha_csv_file = File.join(Rails.root, "db/sedgwick-county-precincts-2016-shas.csv")
    sedgwick2016 = {}
    CSV.foreach(geosha_csv_file, headers: true) do |row|
      sedgwick2016[row['precinct']] = row['geosha']
    end

    # load the explicit CSV mappings
    seen = {}
    csv_file = File.join(Rails.root, 'db/sedgwick-county-precincts-2016.csv')
    CSV.foreach(csv_file, headers: true) do |row|
      reported_name = row['reported_name'] # the alias
      precinct_name = row['precinct']      # primary 1:1 precinct
      census_tracts = (row['census_tracts'] || '').split('|') # secondary overlapping tracts

      if !precinct_name && !census_tracts.any?
        # look up the reported name in the geojson and get the sha
        if sha2016 = sedgwick2016[reported_name]
          locate_precinct(reported_name, sha2016)
        end
      end

      seen[reported_name] = true
    end

    # load orphans
    csv_file = File.join(Rails.root, 'orphans')
    CSV.foreach(csv_file, headers:true) do |row|
      reported_name = row['precinct']
      next if seen[reported_name]

      if sha2016 = sedgwick2016[reported_name]
        locate_precinct(reported_name, sha2016)
      end
    end
  end

  def locate_precinct(reported_name, sha2016)
    puts "found geosha #{sha2016.inspect} for #{reported_name}"

    if vtd = @geo_finder.vtd_for(sha2016)
      puts " > vtd: #{vtd.inspect}"
      if vtd.is_a?(Array)
        vtd.each do |v|
          m = v.match(/^20(\d\d\d)(\w+)$/)
          county_fips = m[1]
          vtd_code = m[2]
          county = County.find_by!(fips: county_fips)
          c = CensusTract.find_by!(vtd_code: vtd_code, county_id: county.id)
          p = c.precinct
          puts " > #{vtd_code} -> #{p.name} [#{p.alias_names.join(',')}]"
        end
      end
    end
  end
end
  
