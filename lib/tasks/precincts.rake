namespace :precincts do
  desc 'load precinct aliasese'
  task aliases: :environment do

  end

  def read_csv_gz(filename, &block)
    Zlib::GzipReader.open(filename) do |gzip|
      csv = CSV.new(gzip, headers: true)
      csv.each do |row|
        yield(row)
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
      tract = CensusTract.find_by(name: name)

      if !tract && precinctid.to_i < 10
        tract = CensusTract.find_by(name: name.gsub(/\d/, "0#{precinctid}"))
      end

      if !tract
        # if we have census_names, that means this precinct is new since the last census (2010)
        # so make sure we create a Precinct for it and map it to an existing CensusTract
        if census_names
          census_names.each do |n|
            c_tract = CensusTract.find_by!(name: n, county_id: douglas.id)
            precinct = Precinct.find_or_create_by(county_id: douglas.id, name: name)
            cp = CensusPrecinct.find_or_create_by(precinct_id: precinct.id, census_tract_id: c_tract.id)
            make_precinct_aliases(precinctid, subprecinctid, precinct.id)
          end
        else
          puts "  ===>>>> no CensusPrecinct or census_names found <<<< '#{name}' #{precinctid} #{subprecinctid}"
        end
        next

      else
        precinct = precinct_for_tract(tract)
        make_precinct_aliases(precinctid, subprecinctid, precinct.id)
      end
    end
  end

  def precinct_for_tract(tract)
    Precinct.find_by(name: tract.name, county_id: tract.county_id) ||
      tract.precincts.first ||
      Precinct.create(name: tract.name, county_id: tract.county_id)
  end

  def make_precinct_aliases(precinctid, subprecinctid, precinct_id)
    [
      "Precinct #{precinctid}-#{subprecinctid}",
      "Precinct #{precinctid} #{subprecinctid}",
      "Prec #{precinctid}-#{subprecinctid}",
      "Prec #{precinctid} #{subprecinctid}"
    ].each do |n|
      PrecinctAlias.find_or_create_by(precinct_id: precinct_id, name: n)
    end
  end
end
