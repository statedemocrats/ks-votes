namespace :precincts do
  namespace :check do
    include TaskHelpers

    desc 'lookup names from openelections csv to compare against db'
    task openelections_file: :environment do
      file = ENV.fetch('FILE')
      fail "FILE= env var required" unless file
      county = nil
      seen = {}
      CSV.foreach(file, headers: true) do |row|
        os_precinct = row['precinct']
        next if os_precinct.downcase == 'totals'
        next if os_precinct.downcase == 'county totals'
        next if seen[os_precinct]

        county ||= County.l(row['county'])
        precinct = Precinct.find_best(os_precinct, county.id)
        if precinct
          puts "#{os_precinct} [#{row['vtd']}] => #{precinct.name} [#{precinct.census_tract_vtds.join(',')}] #{precinct.year}"
        else
          puts "NO MATCH: #{os_precinct} [#{row['vtd']}] #{row['votes']} votes"
        end
        seen[os_precinct] = true
      end
    end

    desc 'duplicate map ids'
    task duplicate_map_ids: :environment do
      seen = {}
      Precinct.find_in_batches do |precincts|
        precincts.each do |p|
          county = find_county_by_id(p.county_id)
          if p.name.match(/\ \ /)
            puts "[#{county.name}] Multiple spaces in name #{green(p.name)}"
          end
          next unless p.census_tract_id # for now, skip those without 1:1 mapping
          next unless p.map_id.length > 0
          if seen[p.map_id] and seen[p.map_id][:year] == p.year
            d = seen[p.map_id].inspect
            puts "[#{county.name}] Duplicate map_id #{p.map_id} for #{p.id} #{green(p.name)} and #{d}"
            if p.year == '2014'
              puts " > [#{county.name}] #{green(p.name)} CensusTract is 2014"
            end
            next
          end
          seen[p.map_id] = {id: p.id, name: p.name, year: p.census_tract.year}
        end
      end
    end

    desc 'duplicate names'
    task duplicate_names: :environment do
      seen = {}
      PrecinctAlias.includes(:precinct).find_in_batches do |aliases|
        aliases.each do |pa|
          county = find_county_by_id(pa.precinct.county_id)
          k = "#{county.name}:#{pa.name}"
          if pa.name.match(/\ \ /)
            puts "[#{county.name}] Multiple spaces in name #{pa.name}"
          end
          if seen[k]
            puts "[#{county.name}] More than one alias #{blue(pa.name)}"
          end
          if p = Precinct.find_by(name: pa.name, county_id: county.id)
            # is it an alias to itself?
            next if p.id == pa.precinct_id
            puts "[#{county.name}] Found alias and precinct with same name: #{blue(pa.name)}"
            if p.census_tract && p.census_tract.year == '2014'
              puts "[#{county.name}] Has CensusTract 2014 #{green(p.name)}"
            end
            if p.results.count > 0
              c = pa.precinct.results.count
              puts "[#{county.name}] Precinct #{blue(pa.name)} has #{p.results.count} Results, PrecinctAlias has #{c}"
            end
          end
        end
      end
    end

    desc 'precincts missing census_track'
    task missing_census_tract: :environment do
      clean_up = ENV['CLEAN_UP']
      Precinct.includes(:census_tract).find_in_batches do |precincts|
        precincts.each do |p|
          unless p.census_tract
            county = find_county_by_id(p.county_id)
            aliases = PrecinctAlias.l(p.name)
            puts "[#{county.name}] Precinct '#{p.name}' (#{p.id}) missing census_tract"
            if aliases
              puts "[#{county.name}] Precinct #{p.id} exists as PrecinctAlias #{aliases.pretty_inspect}"
            end
            if clean_up
              p.destroy
            end
          end
        end
      end
    end
  end
end
