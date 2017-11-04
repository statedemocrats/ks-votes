require 'task_helpers'

namespace :precincts do
  include Term::ANSIColor
  include TaskHelpers

  def county_tasks
    @county_tasks ||= [
      'map_orphans', # master catch-all list FIRST
      'barton',
      'butler',
      'cowley',
      'riley',
      'geary',
      'douglas',
      'saline',
      'shawnee',
      'sedgwick',
      'johnson',
      'wyandotte',
      'vtd2014', # LAST
    ]
  end

  desc 'load precinct aliasese'
  task aliases: :environment do
    county_tasks.each do |t|
      Rake::Task["precincts:#{t}"].invoke
    end
  end

  desc '2014 VTD mapping'
  task vtd2014: :environment do
    json = File.read(File.join(Rails.root, 'db/2014-vtd-county-mapping.json'))
    vtdmap = JSON.parse(json)
    counties = {}
    vtdmap.each do |cty, vtds|
      county = counties[cty] ||= County.l(cty)
      vtds.each do |vtd, precinct_name|
        next if vtd.length != 6  # comes from SOS as 3-digits, likely an internal mapping, not federal.
        next if precinct_name == 'ADVANCED' # comes from SOS, not geographic.

        # if we find an existing alias for precinct_name,
        # prefer it since the 2012 names are 1:1 with our census map.
        # i.e. don't create a CensusTract entry for those.
        if pa = PrecinctAlias.l(precinct_name)
          puts "[#{county.name}] Skipping #{blue(precinct_name)} since alias already exists" if debug?
          next
        end

        ct = CensusTract.find_or_create_by(vtd_code: vtd, county_id: county.id) do |c|
          c.year = '2014'
          c.reason = :sos
          c.name = precinct_name
          puts "[#{county.name}] Creating 2014 CensusTract #{blue(vtd)} #{green(precinct_name)}"
        end

        m = Precinct.find_by_any_name(precinct_name, county.id)
        if !m.any?
          # the name didn't match but perhaps there was a typo at some point.
          # only create a precinct if we had to create the CensusTract.
          if ct.year == '2014' || !ct.precinct
            p = Precinct.create(census_tract_id: ct.id, name: precinct_name, county_id: county.id)
            puts "[#{county.name}] Creating 2014 Precinct #{green(precinct_name)}"
          elsif ct.precinct
            curated_alias(ct.precinct.id, precinct_name)
            puts "[#{county.name}] 2014 VTD Alias #{blue(precinct_name)} -> #{green(ct.precinct.name)}"
          else
            puts "[#{county.name}] No Precinct for CensusTract #{cyan(ct.name)}"
          end
        elsif m && m.length > 1
          puts "[#{county.name}] too many matches for precinct name #{red(precinct_name)}"
          next
        elsif m.first.name == precinct_name || m.first.has_alias?(precinct_name)
          # there existed a Precinct or Alias already for this name.
          # warn if mapped to a different CensusTract
          precinct = m.first
          if precinct.census_tract_id && precinct.census_tract_id != ct.id
            puts "[#{county.name}] Found Precinct #{green(precinct.name)} for #{blue(precinct_name)} but not in CensusTract #{cyan(ct.name)} (ct.id=#{ct.id} precinct.census_precinct_id=#{precinct.census_tract_id} precinct.id=#{precinct.id}"
          end
        else
          puts "[#{county.name}] Found precinct #{blue(m.first.name)} for vtd #{green(vtd)} mismatch #{red(precinct_name)}"
        end
      end
    end
  end
        
  desc 'match orphans'
  task orphans: :environment do
    include Term::ANSIColor
    pf = PrecinctFinder.new
    sql = File.read(File.join(Rails.root, 'sql/orphan-precincts.sql'))
    recs = Precinct.connection.execute(sql)
    recs.each do |r|
      fuzzy = pf.fuzzy_match(r['county'], r['precinct'])
      next if fuzzy == r['precinct']
      puts "[#{blue(r['county'])}] #{r['precinct']} => #{fuzzy}"
    end
  end

  desc 'alias Riley county'
  task riley: :environment do
    riley = County.n('Riley')
    riley.precincts.each do |p|
      if m = p.name.match(/Ward (\d+) Precinct (\d+)$/)
        curated_alias(p.id, sprintf('W%02dP%02d', m[1], m[2]))
      end
      if m = p.name.match(/Manhattan Township Precinct (\d+)$/)
        curated_alias(p.id, sprintf('Manhattan Township %s', m[1]))
        curated_alias(p.id, sprintf('Manhattan twp %s', m[1]))
      end
    end
  end

  desc 'alias Barton county'
  task barton: :environment do
    barton = County.n('Barton')
    barton.precincts.each do |p|
      aliases = []
      if m = p.name.match(/GBC (\d+)\w+ Prec - Ward (\d+)$/)
        precinct = m[1]
        ward = m[2]
        aliases << "Great Bend City Ward #{ward.to_i} Precinct #{precinct.to_i}"
      elsif m = p.name.match(/Great Bend City Ward (\d+) Precinct (\d+)$/)
        ward = m[1]
        precinct = m[2]
        aliases << "GBC #{precinct.to_i.ordinalize} Prec - Ward #{ward.to_i}"
      elsif m = p.name.match(/^Hoisington Ward \d/)
        aliases << p.name.sub('Hoisington', 'Hoisington City')
      end
      aliases.uniq.each do |n|
        curated_alias(p.id, n)
        puts "[Barton] Alias #{blue(n)} -> #{green(p.name)}"
      end
    end
  end

  desc 'Butler county'
  task butler: :environment do
    butler = County.n('Butler')
    butler.precincts.each do |p|
      aliases = []
      if p.name.match(/\b0\d/)
        aliases << p.name.gsub(/(\d+)/) { sprintf('%d', Regexp.last_match[1].to_i) }
      end
      if p.name.match(/\bH\d+/)
        aliases << p.name.gsub(/ H(\d+)/, ' - \1')
      end
      if p.name.match(/\bS\d+/)
        aliases << p.name.gsub(/ S(\d+)/, ' - \1')
      end
      aliases.uniq.each do |n|
        next if n == p.name
        curated_alias(p.id, n)
        puts "[Butler] Alias #{blue(n)} -> #{green(p.name)}"
      end

      # some results are just the plain Ward, so map all the precincts to that Ward record.
      if p.name.match(/El Dorado Ward \d /)
        new_p = Precinct.find_or_create_by(name: p.name.sub(/(Ward \d).+/, '\1'), county_id: butler.id)
        new_p.census_precincts << CensusPrecinct.new(precinct_id: new_p.id, census_tract_id: p.census_tract_id)
        puts "[Butler] Precinct #{green(new_p.name)} mapped to CensusTract #{cyan(p.name)}"
      elsif p.name.match(/Bruno Township .+/)
        new_p = Precinct.find_or_create_by(name: 'Bruno Township', county_id: butler.id)
        new_p.census_precincts << CensusPrecinct.new(precinct_id: new_p.id, census_tract_id: p.census_tract_id)
        puts "[Butler] Precinct #{green(new_p.name)} mapped to CensusTract #{cyan(p.name)}"
      end
    end
  end

  desc 'Cowley county'
  task cowley: :environment do
    cowley = County.n('Cowley')
    cowley.precincts.each do |p|
      aliases = []
      if m = p.name.match(/^Winfield Ward (\d+)$/)
        aliases << "WD#{m[1]}"
        aliases << "Ward #{m[1]}"
      elsif m = p.name.match(/^Winfield Ward (\d+) ([EWNSC])\w+$/)
        aliases << "WD#{m[1]}#{m[2]}"
        aliases << "Ward #{m[1]}#{m[2]}"
      elsif m = p.name.match(/^Arkansas City Ward (\d+) (\w)$/)
        aliases << "AC#{m[1]}#{m[2]}"
      end

      aliases.uniq.each do |n|
        next if n == p.name
        curated_alias(p.id, n)
        puts "[Cowley] Alias #{blue(n)} -> #{green(p.name)}"
      end
    end
  end

  desc 'alias Geary county'
  task geary: :environment do
    geary = County.find_by(name: 'Geary')
    geary.precincts.each do |p|
      aliases = []
      if p.name.match(/^Ward \d/)
        aliases << "Junction City #{p.name}"
      elsif p.name.match(/^Junction City Ward/)
        aliases << p.name.sub('Junction City ', '')
      elsif p.name.match(/^Smokey/)
        aliases << p.name.sub('Smokey', 'Smoky')
      end
      p.precinct_aliases.each do |pa|
        if pa.name.match(/^Smokey/)
          aliases << pa.name.sub('Smokey', 'Smoky')
        end
      end
      aliases.uniq.each do |n|
        # avoid duplicates from manual orphan mapping
        next if Precinct.find_by(name: n, county_id: geary.id)
        next if p.has_alias?(n)
        curated_alias(p.id, n)
        puts "[Geary] Alias #{blue(n)} -> #{green(p.name)}"
      end
    end
  end

  desc 'Saline'
  task saline: :environment do
    saline = County.find_by(name: 'Saline')
    saline.precincts.each do |p|
      if m = p.name.match(/^Salina Precinct (\d+)$/)
        curated_alias(p.id, m[1].to_i)
      end
    end
  end

  desc 'map manual orphan pairings'
  task map_orphans: :environment do
    csv_file = File.join(Rails.root, 'db/orphans.csv')
    CSV.foreach(csv_file, headers: true) do |row|
      next unless row['vtd_2012'] || row['census_tracts']
      precinct = Precinct.find_by(name: row['precinct'], county_id: row['county_id'])
      next if precinct && precinct.census_tract_id
      if row['vtd_2012']
        #puts "looking for CensusTract #{row['vtd_2012']} in county #{row['county']}"
        ct = CensusTract.find_by!(vtd_code: row['vtd_2012'], county_id: row['county_id'])
        # if there's already a precinct, add this one as an alias
        if ct.precincts.count == 1 && !ct.precinct.has_alias?(row['precinct'])
          ct.precinct.precinct_aliases << PrecinctAlias.new(name: row['precinct'])
          puts "[#{row['county']}] Add alias #{blue(row['precinct'])} to precinct #{green(ct.precinct.name)}"
        else
          puts "Not exactly one precinct for CensusTract #{ct.id}"
        end
      elsif row['census_tracts']
        census_tract_vtds = row['census_tracts'].split('|')
        # probably need to create a Precinct
        precinct ||= Precinct.create(name: row['precinct'], county_id: row['county_id'])
        census_tract_vtds.each do |vtd|
          ct = CensusTract.find_by!(vtd_code: vtd, county_id: row['county_id'])
          precinct.census_tracts << ct
          puts "[#{row['county']}] Add CensusTract #{cyan(ct.name)} to new Precinct #{green(precinct.name)}"
        end
      end
    end
  end

  desc 'alias Shawnee county'
  task shawnee: :environment do
    shawnee = County.find_by(name: 'Shawnee')
    csv_file = File.join(Rails.root, 'db/shawnee-county-precincts-2016.csv')
    CSV.foreach(csv_file, headers: true) do |row|
      reported_name = row['reported']
      vtd2010 = row['vtd_2010']
      comment = row['comment']
      bare_name = reported_name.gsub(/^\d+ /, '')
      bare_name.gsub!(/(\d+)/) { sprintf('%02d', Regexp.last_match[1].to_i) }

      # find the first Precinct to match. Order is important since we prefer explicit over derived.
      p = nil
      [reported_name, bare_name].each do |n|
        break if p = Precinct.find_by(name: n, county_id: shawnee.id)
      end
      if vtd2010
        ct = CensusTract.find_by(name: vtd2010, county_id: shawnee.id)
        if !ct
          puts "[Shawnee] census tract not found #{red(vtd2010)}"
          next
        elsif !p && !comment
          # couldn't find precinct with name reported, so use the vtd2010, unless we commented about it.
          p = ct.precinct
          puts "[Shawnee] Could not find Precinct for #{blue(reported_name)} so using CensusTract #{green(vtd2010)}"
        else
          # re-point the Precinct at the CensusTract if it is not already.
          # Shawnee re-used names from the 2010 census to point at different precincts,
          # and we have manually mapped them so that election Results name (Precinct) point at the correct
          # geography (CensusTract)
          if !p
            p = Precinct.create(name: reported_name, county_id: shawnee.id, census_tract_id: ct.id)
            puts "[Shawnee] Created Precinct #{green(reported_name)} for CensusTract #{ct.id} #{blue(ct.name)}"
          end
          if p.census_tract_id != ct.id
            puts "[Shawnee] re-pointing Precinct #{green(p.id.to_s)} at CensusTract #{blue(ct.id.to_s)} from #{cyan(p.census_tract_id.to_s)}"
            p.census_tract_id = ct.id
            p.save!
          end
        end
      elsif !p
        puts "[Shawnee] No vtd2010 value, no Precinct found for #{red(reported_name)} or #{red(bare_name)}"
        next
      end

      # alias all permutations of the reported_name
      int_name = bare_name.gsub(/(\d+)/) { sprintf('%d', Regexp.last_match[1].to_i) }
      ward_name = int_name.gsub(/^Topeka /, '')
      [reported_name, bare_name, int_name, ward_name].uniq.each do |n|
        next if n == p.name
        curated_alias(p.id, n)
        puts "[Shawnee] Alias #{blue(n)} -> #{green(p.name)}"
      end
    end
    shawnee.precincts.order(:name).each do |p|
      if m = p.name.match(/^Topeka Ward (\d+) Precinct (\d+)$/)
        aliases = [
          p.name.upcase,
          "Ward #{m[1]} Precinct #{m[2]}",
          "Ward #{m[1].to_i} Precinct #{m[2].to_i}",
          sprintf("W %d P %d", m[1].to_i, m[2].to_i),
          sprintf("W %d P %02d", m[1].to_i, m[2].to_i),
          sprintf("W %02d P %d", m[1].to_i, m[2].to_i),
          sprintf("W %02d P %02d", m[1].to_i, m[2].to_i),
        ]
        if m[1].to_i < 10 || m[2].to_i < 10
          aliases << sprintf("Topeka Ward %02d Precinct %02d", m[1].to_i, m[2].to_i)
          aliases << sprintf("Topeka Ward %d Precinct %02d", m[1].to_i, m[2].to_i)
          aliases << sprintf("Topeka Ward %02d Precinct %d", m[1].to_i, m[2].to_i)
          aliases << sprintf("Topeka Ward %d Precinct %d", m[1].to_i, m[2].to_i)
        end
        aliases.uniq.each do |n|
          next if n == p.name
          curated_alias(p.id, n)
          puts "[Shawnee] Alias permutation #{blue(n)} -> #{green(p.name)}"
        end
      end
    end
  end

  def sedgwick_palias_formatted(precinct_id, name, abbr, matches)
    aliases = []
    aliases << name.upcase
    if matches[2]
      w = matches[1].to_i
      p = matches[2].to_i
      aliases << sprintf("#{abbr}%02d%02d", w, p)
      aliases << sprintf("#{abbr}%d%d", w, p)
      aliases << name.gsub("Ward #{w} Precinct #{p}", sprintf("Ward %02d Precinct %02d", w, p))
    else
      p = matches[1].to_i
      aliases << sprintf("#{abbr}%02d", p)
      aliases << sprintf("#{abbr}%d", p)
      aliases << name.gsub(matches[1], sprintf("%02d", p))
    end
    aliases.each do |n|
      next if n == name
      curated_alias(precinct_id, n)
      puts "[Sedgwick] Alias #{n} -> #{name}"
    end
  end

  desc 'Sedgwick'
  task sedgwick: :environment do
    sedgwick = County.find_by(name: 'Sedgwick')

    sedgwick_create_aliases(sedgwick) # call before geosha lookup, and again at end
    county_2016_geosha_lookup('Sedgwick') # MUST call before sedgwick_map_2016_precincts
    sedgwick_map_2016_precincts(sedgwick)
    sedgwick_create_aliases(sedgwick) # MUST call last
  end

  desc 'Sedgwick Geosha lookup'
  task sedgwick_geosha: :environment do
    county_2016_geosha_lookup('Sedgwick')
  end

  def county_2016_geosha_lookup(county_name)
    csv_file = File.join(Rails.root, "db/#{county_name.downcase}-county-precincts-2016-shas.csv")
    geo_finder = GeoFinder.new
    CSV.foreach(csv_file, headers: true) do |row|
      precinct_name_2016 = row['precinct']
      sha = row['geosha']
      if geo_finder.vtd_for(sha)
        vtd_2012 = geo_finder.vtd_for(sha)

        next if vtd_2012.is_a?(Array) # ambiguous match

        puts "[#{county_name}] Found geosha match #{precinct_name_2016} -> #{vtd_2012} #{sha.truncate(12)}"
        # data oddity has a precinct switching counties between 2012 and 2016
        # thanks to geosha we see the collision, and must get the county from the FIPS code.
        m = vtd_2012.match(/^20(\d\d\d)(\w+)$/)
        county_fips = m[1]
        vtd_code = m[2]
        cty = county_by_fips(county_fips)
        c = CensusTract.find_by(vtd_code: vtd_code, county_id: cty.id)
        fail "[#{cty.name}] No CensusTract for #{vtd_code}" unless c
        p = c.precinct
        unless p.has_alias?(precinct_name_2016)
          pa = curated_alias(precinct_name_2016, p.id)
          puts "[#{county_name}] Created PrecinctAlias #{precinct_name_2016} -> #{p.name}"
        end
      end
    end
  end

  def sedgwick_precinct_abbrs
    @_sedgwick ||= {
      'Afton' => 'AF',
      'Attica' => 'AT',
      'Bel Aire' => 'BA',
      'Delano' => 'DL',
      'Derby' => 'DB',
      'Eagle' => 'EA',
      'Erie' => 'ER',
      'Garden Plain' => 'GA',
      'Grand River' => 'GD',
      'Grant' => 'GN',
      'Greeley' => 'GR',
      'Gypsum' => 'GY',
      'Haysville' => 'HA',
      'Illinois' => 'IL',
      'Kechi' => 'KE',
      'Lincoln' => 'LI',
      'Minneha' => 'MI',
      'Morton' => 'MO',
      'Mulvane' => 'MV',
      'Mulvane City' => 'MV',
      'Ninnescah' => 'NI',
      'Ohio' => 'OH',
      'Park City' => 'PC',
      'Park' => 'PA',
      'Payne' => 'PY',
      'Riverside' => 'RI',
      'Rockford' => 'RO',
      'Salem' => 'SA',
      'Sherman' => 'SH',
      'Union' => 'UN',
      'Valley Center' => 'VC',
      'Valley Center City' => 'VC',
      'Valley Center Township' => 'VA',
      'Viola' => 'VI',
      'Waco' => 'WA',
      'Wichita' => '',
    }
  end

  def sedgwick_create_aliases(sedgwick)
    sedgwick.precincts.each do |p|
      p_name = p.name
      if abbr = sedgwick_precinct_abbrs[p_name]
        curated_alias(p.id, abbr)
      elsif n = p_name.match(/^([\ A-Za-z]+?) (Ward|Precinct) (\d+)/)
        long_name = n[1]
        abbr = sedgwick_precinct_abbrs[long_name] or fail "No Sedgwick abbreviation for #{p_name} [#{long_name}]"
        if abbr == '' # i.e. Wichita
          if m = p_name.match(/^Wichita Precinct (\d+)$/)
            curated_alias(p.id, m[1])
          elsif m = p.name.match(/^Wichita Precinct (\d+)/) # might have leg district suffix
            p_id = m[1]
            if p.alias_names.include? "WICHITA PRECINCT #{p_id}"
              curated_alias(p.id, p_id)
            end
          end
        elsif long_name.match(/^(Mulvane|Valley Center) City /)
          curated_alias(p.id, p.name.sub(' City', ''))

        # Ward + Precinct patterns
        elsif m = p_name.match(/ Ward (\d+) Precinct (\d+)$/)
          sedgwick_palias_formatted(p.id, p_name, abbr, m) if abbr.length > 0
        elsif m = p_name.match(/ Precinct (\d+)$/)
          #puts "p_name: #{p_name} abbr:#{abbr} m: #{m.inspect}"
          sedgwick_palias_formatted(p.id, p_name, abbr, m) if abbr.length > 0
        elsif m = p_name.match(/ Ward (\d+) Precinct (\d+) (.+)$/)
          # if it has an alias already for the abbr+precinct, assume it is the "main" precinct
          pa = "#{abbr}#{m[1].to_i}#{m[2].to_i}"
          long_pa = "#{long_name} Ward #{m[1]} Precinct #{m[2]}"
          if p.has_alias?(pa) && !p.has_alias?(long_pa)
            curated_alias(long_pa, p.id)
          end
        elsif m = p_name.match(/ Precinct (\d+) (.+)$/)
          pa = "#{abbr}#{sprintf("%02d", m[1].to_i)}"
          long_pa = "#{long_name} Precinct #{m[1]}"
          if p.has_alias?(pa) && !p.has_alias?(long_pa)
            curated_alias(long_pa, p.id)
          end
        end
      # odd
      elsif p_name.match(/^Valley Center Township/)
        curated_alias(p.id, sedgwick_precinct_abbrs['Valley Center Township'])
      else
        fail "Unexpected Sedgwick precinct name #{p_name}"
      end
    end
  end

  def sedgwick_map_2016_precincts(sedgwick)
    csv_file = File.join(Rails.root, 'db/sedgwick-county-precincts-2016.csv')
    CSV.foreach(csv_file, headers: true) do |row|
      reported_name = row['reported_name'] # the alias
      precinct_name = row['precinct']      # primary 1:1 precinct
      census_tracts = (row['census_tracts'] || '').split('|') # secondary overlapping tracts
      if precinct_name
        p = Precinct.find_by!(name: precinct_name, county_id: sedgwick.id)
        pa = curated_alias(p.id, reported_name)
        puts "[Sedgwick] Alias #{reported_name} -> #{precinct_name}"
      elsif census_tracts.any?
        p = Precinct.find_by_any_name(reported_name, sedgwick.id).first
        if !p
          # last gasp - create the precinct
          p = Precinct.create!(name: reported_name, county_id: sedgwick.id)
          puts "[Sedgwick] Created Precinct #{reported_name}"
        end
        census_tracts.each do |ct|
          c = CensusTract.find_by!(name: ct, county_id: sedgwick.id)
          cp = CensusPrecinct.find_or_create_by(precinct_id: p.id, census_tract_id: c.id)
          puts "[Sedgwick] CensusPrecinct #{ct} <-> #{reported_name}"
        end
      elsif m = reported_name.match(/^WICHITA PRECINCT (\d+)$/)
        p = Precinct.find_by_any_name(m[1], sedgwick.id).first
        if p
          pa = curated_alias(p.id, reported_name)
          puts "[Sedgwick] Alias #{reported_name} -> #{p.name}"
        end
      else
        puts "[Sedgwick] Skipping incomplete row for #{reported_name}"
      end
    end
  end

  desc 'Johnson'
  task johnson: :environment do
    johnson = County.find_by(name: 'Johnson')
    csv_file = File.join(Rails.root, 'db/johnson-county-precincts-2016.csv')
    CSV.foreach(csv_file, headers: true) do |row|
      reported_name = row['reported']
      precinct = row['precinct']
      census_tract = row['census_tract']
      next unless (precinct || census_tract)
      #puts row.inspect
      r = Precinct.find_by(name: reported_name, county_id: johnson.id)
      p = Precinct.find_by(name: precinct, county_id: johnson.id)
      c = CensusTract.find_by(name: census_tract, county_id: johnson.id)
      if r
        # precinct with the reported name already exists (yes JoCo is crazy for re-using names)
        # when we see a result for this precinct, we want to use the precinct-as-reported
        # TODO
        puts "[Johnson] Found existing precinct for #{reported_name}"
      elsif p
        pa = curated_alias(p.id, reported_name)
        puts "[Johnson] Created PrecinctAlias #{pa.id} for #{reported_name} -> #{precinct}"
      elsif c
        p = Precinct.create(name: reported_name, county_id: johnson.id)
        cp = CensusPrecinct.find_or_create_by(census_tract_id: c.id, precinct_id: p.id)
        puts "[Johnson] Created Precinct #{reported_name} and CensusPrecinct #{c.id} for Tract #{census_tract}"
      else
        $stderr.puts "[Johnson] Failed to find Precinct or CensusTract for #{reported_name}"
      end
    end

    county_2016_geosha_lookup('Johnson')

    johnson.precincts.each do |p|
      aliases = []
      ward = nil
      precinct = nil
      city = nil
      if m = p.name.match(/(\d+)-(\d+)$/)
        ward = sprintf("%02d", m[1].to_i)
        precinct = sprintf("%02d", m[2].to_i)
      else
        next
      end
      if m = p.name.match(/^(Gardner|Olathe|Shawnee) \d/)
        city = "#{m[1]} City"
      else
        city = p.name.sub(/ \d+-\d+$/, '')
      end
      if ward != "00"
        aliases << "#{city} Ward #{ward} Precinct #{precinct}"
        aliases << "#{city} Ward #{ward.to_i} Precinct #{precinct.to_i}"
      elsif ward == "00"
        aliases << "#{city} Precinct #{precinct}"
        aliases << "#{city} Precinct #{precinct.to_i}"
      else
        aliases << p.name.sub(/\d+-\d+$/, "Ward #{ward} Precinct #{precinct}")
        aliases << p.name.sub(/\d+-\d+$/, "Ward #{ward.to_i} Precinct #{precinct.to_i}")
      end
      aliases.uniq.each do |n|
        next if n == p.name
        next if p.has_alias?(n)
        curated_alias(p.id, n)
        puts "[Johnson] Alias #{blue(n)} -> #{green(p.name)}"
      end
    end
  end

  desc 'Wyandotte'
  task wyandotte: :environment do
    csv_file = File.join(Rails.root, 'db/wyandotte-county-precincts-2016.csv')
    wyandotte = County.find_by(name: 'Wyandotte')
    city_abbrs = {
      'Kansas City' => 'KC',
      'Lake Quivira' => 'QC',
      'Delaware Township' => 'DE',
      'Edwardsville' => 'ED',
      'Bonner Springs' => 'BS',
    }
    CSV.foreach(csv_file, headers: true) do |row|
      vtd_code = row['VTD_S']
      ward = row['WARD']
      precinct = row['PRECINCT']
      city = row['CITY']
      abbr = city_abbrs[city] or fail "Wyandotte - no city abbreviation for #{city}"
      short = sprintf("%s %s-%s", abbr, ward, precinct)
      name = sprintf("%s Ward %d Precinct %02d", city, ward.to_i, precinct.to_i)
      alt_name = sprintf("%s Ward %02d Precinct %02d", city, ward.to_i, precinct.to_i)
      if p = Precinct.find_by(name: [name, alt_name], county_id: wyandotte.id)
        unless p.has_alias?(short)
          pa = curated_alias(p.id, short)
          puts "[Wyandotte] Alias short #{blue(short)} -> #{green(name)}"
        end
        if p.name != alt_name && !p.has_alias?(alt_name)
          pa = curated_alias(p.id, alt_name)
          puts "[Wyandotte] Alias alt #{blue(alt_name)} -> #{green(name)}"
        end
      elsif ct = CensusTract.find_by(vtd_code: vtd_code, county_id: wyandotte.id)
        p = ct.precinct
        unless p.has_alias?(short)
          pa = curated_alias(p.id, short)
          puts "[Wyandotte] Alias short #{blue(short)} -> #{green(p.name)} (via CensusTract #{vtd_code})"
        end
        if alt_name != name && !p.has_alias?(alt_name)
          pa = curated_alias(p.id, alt_name)
          puts "[Wyandotte] Alias alt #{blue(alt_name)} -> #{green(name)} (via CensusTract #{vtd_code})"
        end
      # census.gov failed to include some from the county, maybe created after 2010...
      elsif row['DATEMOD'].match(/2012/)
        ct = CensusTract.create(vtd_code: vtd_code, county_id: wyandotte.id, name: name, reason: :curated, year: '2012')
        p = Precinct.create(name: name, census_tract_id: ct.id, county_id: wyandotte.id)
        puts "[Wyandotte] Created CensusTract and Precinct #{green(name)} with VTD #{vtd_code}"
        curated_alias(p.id, alt_name)
        curated_alias(p.id, short)
        puts "[Wyandotte] Alias short #{blue(short)} -> #{green(p.name)}"
        puts "[Wyandotte] Alias alt #{blue(alt_name)} -> #{green(p.name)}"
      else
        puts "[Wyandotte] cannot locate Precinct #{name} or CensusTract #{vtd_code} for #{row.inspect}"
      end
    end

    # odds and ends
    CSV.foreach(File.join(Rails.root, 'db/wyandotte-county-precincts-2016-mappings.csv'), headers: true) do |row|
      precinct_name = row['precinct']
      alias_names = row['aliases'].split('|')
      p = Precinct.find_by!(name: precinct_name, county_id: wyandotte.id)
      alias_names.each do |n|
        next if p.has_alias?(n)
        ct = CensusTract.find_by(name: n, county_id: wyandotte.id)
        if ct && ct.id != p.census_tract_id
          puts "[Wyandotte] Found existing CensusTract for alias #{blue(n)} - reassigning Precinct"
          p.census_tract_id = ct.id
          p.save!
          next
        end

        curated_alias(p.id, n)
        puts "[Wyandotte] Alias mapped #{blue(n)} -> #{green(precinct_name)}"
      end
    end
  end

  desc 'load Douglas county'
  task douglas: :environment do
    csv_file = File.join(Rails.root, 'db/douglas-county-precincts-2016.csv')
    douglas = County.find_by(name: 'Douglas')
    CSV.foreach(csv_file, headers: true) do |row|
      name = row[0]
      precinctid = row[1]
      subprecinctid = row[2]
      census_names = row[3].split(/\|/) if row[3]

      #puts "'#{name}' #{precinctid} #{subprecinctid}"

      # find the authoritative census area
      tract = CensusTract.find_by(name: name, county_id: douglas.id)

      if !tract && precinctid.to_i < 10
        prefixed_name = name.gsub(/Precinct \d/, "Precinct 0#{precinctid}")
        tract = CensusTract.find_by(name: prefixed_name, county_id: douglas.id)
      end

      if !tract
        # if we have census_names, that means this precinct is new since the last census (2010)
        # so make sure we create a Precinct for it and map it to an existing CensusTract
        if census_names
          census_names.each do |n|
            c_tract = CensusTract.find_by!(name: n, county_id: douglas.id)
            precinct = Precinct.find_or_create_by(county_id: douglas.id, name: name)
            cp = CensusPrecinct.find_or_create_by(precinct_id: precinct.id, census_tract_id: c_tract.id)
            douglas_make_precinct_aliases(name, precinctid, subprecinctid, precinct.id)
          end
        end
        next

      else
        precinct = precinct_for_tract(tract)
        douglas_make_precinct_aliases(name, precinctid, subprecinctid, precinct.id)
      end
    end

    douglas.precincts.each do |p|
      next unless p.name.match(/^Lawrence Precinct/)
      n = p.name.sub(/^Lawrence Precinct /, '').gsub(/(\d+)/) { Regexp.last_match[1].to_i }
      curated_alias(p.id, n)
      puts "[Douglas] Alias #{blue(n)} -> #{green(p.name)}"
    end
  end

  def douglas_make_precinct_aliases(name, precinctid, subprecinctid, precinct_id)
    aliases = [
      name.gsub(/^.+? Precinct/, 'Precinct'),
      "Precinct #{precinctid}-#{subprecinctid}",
      "Precinct #{precinctid} #{subprecinctid}",
      "Prec #{precinctid}-#{subprecinctid}",
      "Prec #{precinctid} #{subprecinctid}"
    ]
    if subprecinctid.to_i == 1
      aliases << "Precinct #{precinctid}"
      aliases << "Prec #{precinctid}"
    end
    if precinctid.to_i < 10 && precinctid.match(/^\d$/)
      aliases << "Precinct 0#{precinctid}-#{subprecinctid}"
      aliases << "Precinct 0#{precinctid} #{subprecinctid}"
      aliases << "Precinct 0#{precinctid}" if subprecinctid.to_i == 1
      aliases << "Prec 0#{precinctid}-#{subprecinctid}"
      aliases << "Prec 0#{precinctid} #{subprecinctid}"
      aliases << "Prec 0#{precinctid}" if subprecinctid.to_i == 1
    end

    aliases.each do |n|
      curated_alias(precinct_id, n)
    end
  end
end
