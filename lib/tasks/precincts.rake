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
    shawnee.precincts.each do |p|
      if m = p.name.match(/^Topeka Ward (\d+) Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "Ward #{m[1]} Precinct #{m[2]}")
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "Ward #{m[1].to_i} Precinct #{m[2].to_i}")
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: sprintf("W %02d P %02d", m[1].to_i, m[2].to_i))
      end
    end
    csv_file = File.join(Rails.root, 'db/shawnee-county-precincts-2016.csv')
    CSV.foreach(csv_file, headers: true) do |row|
      reported_name = row['reported']
      vtd2010 = row['vtd']
      bare_name = reported_name.gsub(/^\d+ /, '')
      p = Precinct.find_by(name: (vtd2010 || bare_name), county_id: shawnee.id)
      unless p
        puts "Shawnee precinct not found: #{vtd2010 || bare_name} [#{reported_name}]"
        next
      end
    end
  end

  desc 'Sedgwick'
  task sedgwick: :environment do
    sedgwick = County.find_by(name: 'Sedgwick')
    sedgwick.precincts.each do |p|
      if p.name == 'Afton'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "AF")
      elsif m = p.name.match(/^Attica Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "AT#{m[1]}")
      elsif m = p.name.match(/^Bel Aire Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "BA#{m[1]}")
      elsif m = p.name.match(/^Delano Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "DL#{m[1]}")
      elsif m = p.name.match(/^Derby Ward (\d+) Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "DB#{m[1].to_i}#{m[2].to_i}")
      elsif p.name == 'Eagle'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "EA")
      elsif p.name == 'Erie'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "ER")
      elsif p.name == 'Garden Plain'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GA")
      elsif p.name == 'Grand River'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GD")
      elsif m = p.name.match(/^Grant Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GN#{m[1]}")
      elsif p.name == 'Greeley'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GR")
      elsif m = p.name.match(/^Gypsum Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "GY#{m[1]}")
      elsif m = p.name.match(/^Haysville Ward (\d+) Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "HA#{m[1].to_i}#{m[2].to_i}")
      elsif m = p.name.match(/^Illinois Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "IL#{m[1]}")
      elsif m = p.name.match(/^Kechi Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "KE#{m[1]}")
      elsif p.name == 'Lincoln'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "LI")
      elsif m = p.name.match(/^Minneha Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "MI#{m[1]}")
      elsif p.name == 'Morton'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "MO")
      elsif m = p.name.match(/^Mulvane City Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "MV#{m[1]}")
      elsif m = p.name.match(/^Ninnescah Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "NI")
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "NI#{m[1]}")
      elsif m = p.name.match(/^Ohio Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "OH#{m[1]}")
      elsif m = p.name.match(/^Park City Ward (\d+) Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "PC#{m[1].to_i}#{m[2].to_i}")
      elsif m = p.name.match(/^Park Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "PA#{m[1]}")
      elsif m = p.name.match(/^Payne Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "PY#{m[1]}")
      elsif m = p.name.match(/^Riverside Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "RI#{m[1]}")
      elsif m = p.name.match(/^Rockford Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "RO#{m[1]}")
      elsif m = p.name.match(/^Salem Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "SA#{m[1]}")
      elsif p.name == 'Sherman'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "SH")
      elsif m = p.name.match(/^Union Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "UN#{m[1]}")
      elsif m = p.name.match(/^Valley Center City Ward (\d+) Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "VC#{m[1].to_i}#{m[2].to_i}")
      elsif m = p.name.match(/^Valley Center Township/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "VA")
      elsif p.name == 'Viola'
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "VI")
      elsif m = p.name.match(/^Waco Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: "WA#{m[1]}")
      elsif m = p.name.match(/^Wichita Precinct (\d+)/)
        PrecinctAlias.find_or_create_by(precinct_id: p.id, name: m[1])
      end
    end
  end

  desc 'Johnson'
  task johnson: :environment do
  end

  desc 'Wyandotte'
  task wyandotte: :environment do
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
          puts "  ===>>>> no CensusPrecinct or census_names found <<<< '#{name}' #{precinctid} #{subprecinctid}"
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
