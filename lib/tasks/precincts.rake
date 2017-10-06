namespace :precincts do
  desc 'load precinct aliasese'
  task aliases: :environment do
    my_tasks = [
      'riley',
      'douglas',
      'shawnee',
      'sedgwick',
      'johnson',
      'wyandotte',
    ]
    my_tasks.each do |t|
      Rake::Task["precincts:#{t}"].invoke
    end
  end

  def read_csv_gz(filename, &block)
    Zlib::GzipReader.open(filename) do |gzip|
      csv = CSV.new(gzip, headers: true)
      csv.each do |row|
        yield(row)
      end
    end
  end

  desc 'alias Riley county'
  task riley: :environment do
    riley = County.find_by(name: 'Riley')
    riley.precincts.each do |p|
      if m = p.name.match(/Ward (\d+) Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: sprintf('W%02dP%02d', m[1], m[2]))
      end
      if m = p.name.match(/Manhattan Township Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: sprintf('Manhattan Township %s', m[1]))
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: sprintf('Manhattan twp %s', m[1]))
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
      bare_name = reported_name.gsub(/^\d+ /, '')
      p = Precinct.find_by(name: (vtd2010 || bare_name), county_id: shawnee.id)
      unless p
        puts "[Shawnee] precinct not found: #{vtd2010 || bare_name} [#{reported_name}]"
        next
      end
      PrecinctAlias.find_or_create_by(precinct_id: p.id, name: reported_name)
      PrecinctAlias.find_or_create_by(precinct_id: p.id, name: bare_name) if bare_name != reported_name
    end
    shawnee.precincts.each do |p|
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
        aliases.each do |n|
          next if n == p.name
          PrecinctAlias.find_or_create_by(precinct_id: p.id, name: n)
          puts "[Shawnee] Alias #{n} -> #{p.name}"
        end
      end
    end
  end

  def sedgwick_palias_formatted(precinct_id, name, abbr, matches)
    aliases = []
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
      PrecinctAlias.find_or_create_by(precinct_id: precinct_id, name: n)
      puts "[Sedgwick] Alias #{n} -> #{name}"
    end
  end

  desc 'Sedgwick'
  task sedgwick: :environment do
    sedgwick = County.find_by(name: 'Sedgwick')

    county_2016_geosha_lookup('Sedgwick') # MUST call before sedgwick_map_2016_precincts
    sedgwick_map_2016_precincts(sedgwick)
    sedgwick_create_aliases(sedgwick) # MUST call last
  end

  desc 'Sedgwick Geosha lookup'
  task sedgwick_geosha: :environment do
    county_2016_geosha_lookup('Sedgwick')
  end

  def kansas2012_geosha
    # load all of Kansas into hash for easy lookup by sha
    @_kansas2012 ||= begin
      buf = {}
      seen = {}
      CSV.foreach(File.join(Rails.root, 'db/kansas-2012-vtd-shas.csv'), headers: true) do |row|
        s = row['sha']
        seen[s] ||= 0
        seen[s] += 1
        buf[s] = row['vtd_2012']
      end
      # prune out any duplicates
      seen.each do |s, count|
        if count > 1
          buf.delete(s)
          puts "Removing duplicate sha #{s} from KS 2012 list"
        end
      end
      buf
    end
  end

  def county_by_fips(county_fips)
    @_cbyfips ||= {}
    @_cbyfips[county_fips] ||= County.find_by!(fips: county_fips)
  end

  def county_2016_geosha_lookup(county_name)
    csv_file = File.join(Rails.root, "db/#{county_name.downcase}-county-precincts-2016-shas.csv")
    CSV.foreach(csv_file, headers: true) do |row|
      precinct_name_2016 = row['precinct']
      sha = row['geosha']
      if kansas2012_geosha[sha]
        vtd_2012 = kansas2012_geosha[sha]
        puts "[#{county_name}] Found geosha match #{precinct_name_2016} -> #{vtd_2012} #{sha.truncate(12)}"
        # data oddity has a precinct switching counties between 2012 and 2016
        # thanks to geosha we see the collision, and must get the county from the FIPS code.
        m = vtd_2012.match(/^20(\d\d\d)(\w+)$/)
        county_fips = m[1]
        vtd_code = m[2]
        cty = county_by_fips(county_fips)
        c = CensusTract.find_by!(vtd_code: vtd_code, county_id: cty.id)
        p = c.precinct
        unless p.has_alias?(precinct_name_2016)
          pa = PrecinctAlias.find_or_create_by(name: precinct_name_2016, precinct_id: p.id)
          puts "[#{county_name}] Created PrecinctAlias #{precinct_name_2016} -> #{p.name}"
        end
      end
    end
  end

  def sedgwick_create_aliases(sedgwick)
    sedgwick.precincts.each do |p|
      PrecinctAlias.find_or_create_by(precinct_id: p.id, name: p.name.upcase)
      if p.name == 'Afton'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "AF")
      elsif m = p.name.match(/^Attica Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'AT', m)
      elsif m = p.name.match(/^Bel Aire Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'BA', m)
      elsif m = p.name.match(/^Delano Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'DL', m)
      elsif m = p.name.match(/^Derby Ward (\d+) Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'DB', m)
      elsif p.name == 'Eagle'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "EA")
      elsif p.name == 'Erie'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "ER")
      elsif p.name == 'Garden Plain'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GA")
      elsif p.name == 'Grand River'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GD")
      elsif m = p.name.match(/^Grant Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'GN', m)
      elsif p.name == 'Greeley'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GR")
      elsif m = p.name.match(/^Gypsum Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'GY', m)
      elsif m = p.name.match(/^Haysville Ward (\d+) Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'HA', m)
      elsif m = p.name.match(/^Illinois Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'IL', m)
      elsif m = p.name.match(/^Kechi Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'KE', m)
      elsif p.name == 'Lincoln'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "LI")
      elsif m = p.name.match(/^Minneha Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'MI', m)
      elsif p.name == 'Morton'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "MO")
      elsif m = p.name.match(/^Mulvane City Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'MV', m)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: sprintf("Mulvane Precinct %02f", m[1].to_i))
      elsif m = p.name.match(/^Ninnescah Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'NI', m)
      elsif m = p.name.match(/^Ohio Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'OH', m)
      elsif m = p.name.match(/^Park City Ward (\d+) Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'PC', m)
      elsif m = p.name.match(/^Park Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'PA', m)
      elsif m = p.name.match(/^Payne Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'PY', m)
      elsif m = p.name.match(/^Riverside Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'RI', m)
      elsif m = p.name.match(/^Rockford Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'RO', m)
      elsif m = p.name.match(/^Salem Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'SA', m)
      elsif p.name == 'Sherman'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "SH")
      elsif m = p.name.match(/^Union Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'UN', m)
      elsif m = p.name.match(/^Valley Center City Ward (\d+) Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'VC', m)
      elsif m = p.name.match(/^Valley Center Township/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "VA")
      elsif p.name == 'Viola'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "VI")
      elsif m = p.name.match(/^Waco Precinct (\d+)$/)
        sedgwick_palias_formatted(p.id, p.name, 'WA', m)
      elsif m = p.name.match(/^Wichita Precinct (\d+)$/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: m[1])
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
        pa = PrecinctAlias.find_or_create_by(precinct_id: p.id, name: reported_name)
        puts "[Sedgwick] Alias #{reported_name} -> #{precinct_name}"
      elsif census_tracts.any?
        p = Precinct.find_by_any_name(reported_name).select {|p| p.county_id == sedgwick.id }.first
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
        p = Precinct.find_by_any_name(m[1]).select {|p| p.county_id == sedgwick.id }.first
        if p
          pa = PrecinctAlias.find_or_create_by(name: reported_name, precinct_id: p.id)
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
        pa = PrecinctAlias.find_or_create_by(precinct_id: p.id, name: reported_name)
        puts "[Johnson] Created PrecinctAlias #{pa.id} for #{reported_name} -> #{precinct}"
      elsif c
        p = Precinct.create(name: reported_name, county_id: johnson.id)
        cp = CensusPrecinct.find_or_create_by(census_tract_id: c.id, precinct_id: p.id)
        puts "[Johnson] Created Precinct #{reported_name} and CensusPrecinct #{c.id} for Tract #{census_tract}"
      else
        $stderr.puts "[Johnson] Failed to find Precinct or CensusTract for #{reported_name}"
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
        pa = PrecinctAlias.find_or_create_by(name: short, precinct_id: p.id)
        puts "[Wyandotte] Alias #{short} -> #{name}"
        if p.name != alt_name
          pa = PrecinctAlias.find_or_create_by(name: alt_name, precinct_id: p.id)
          puts "[Wyandotte] Alias #{alt_name} -> #{name}"
        end
      elsif ct = CensusTract.find_by(vtd_code: vtd_code, county_id: wyandotte.id)
        p = ct.precinct
        pa = PrecinctAlias.find_or_create_by(name: short, precinct_id: p.id)
        puts "[Wyandotte] Alias #{short} -> #{p.name} (via CensusTract #{vtd_code})"
        if alt_name != name
          pa = PrecinctAlias.find_or_create_by(name: alt_name, precinct_id: p.id)
          puts "[Wyandotte] Alias #{alt_name} -> #{name}"
        end
      else
        puts "[Wyandotte] cannot locate Precinct #{name} or CensusTract #{vtd_code} for #{row.inspect}"
      end
    end

    # odds and ends
    qc = Precinct.find_by!(name: 'Lake Quivira City 1', county_id: wyandotte.id)
    PrecinctAlias.find_or_create_by(name: 'Lake Quivira City Precinct 1', precinct_id: qc.id)
    PrecinctAlias.find_or_create_by(name: 'Lake Quivira City Precinct 01', precinct_id: qc.id)

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
            make_precinct_aliases(name, precinctid, subprecinctid, precinct.id)
          end
        else
          puts "[Douglas] no CensusPrecinct or census_names found for #{row.inspect}"
        end
        next

      else
        precinct = precinct_for_tract(tract)
        make_precinct_aliases(name, precinctid, subprecinctid, precinct.id)
      end
    end
  end

  def precinct_for_tract(tract)
    tract.precinct ||
      Precinct.find_by(name: tract.name, county_id: tract.county_id) ||
      tract.precincts.first ||
      Precinct.create(name: tract.name, county_id: tract.county_id)
  end

  def make_precinct_aliases(name, precinctid, subprecinctid, precinct_id)
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
      PrecinctAlias.find_or_create_by(precinct_id: precinct_id, name: n)
    end
  end
end
