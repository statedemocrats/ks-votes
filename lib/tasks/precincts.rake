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

      # find the authoritative census_precinct
      cp = CensusPrecinct.find_by(name: name)

      if !cp && precinctid.to_i < 10
        cp = CensusPrecinct.find_by(name: name.gsub(/\d/, "0#{precinctid}"))
      end

      if !cp
        # if we have census_names, that means this precinct is new since the last census (2010)
        # so make sure we create a Precinct for it and map it to an existing CensusPrecinct
        if census_names
          census_names.each do |n|
            cp = CensusPrecinct.find_by!(name: n, county_id: douglas.id)
            Precinct.find_or_create_by(county_id: douglas.id, name: name) do |p|
              p.census_precinct_id = cp.id
            end
            make_precinct_aliases(precinctid, subprecinctid, cp)
          end
        else
          puts "  ===>>>> no CensusPrecinct or census_names found <<<< '#{name}' #{precinctid} #{subprecinctid}"
        end
        next

      else
        make_precinct_aliases(precinctid, subprecinctid, cp)
      end
    end
  end

  def make_precinct_aliases(precinctid, subprecinctid, cp)
    [
      "Precinct #{precinctid}-#{subprecinctid}",
      "Precinct #{precinctid} #{subprecinctid}",
      "Prec #{precinctid}-#{subprecinctid}",
      "Prec #{precinctid} #{subprecinctid}"
    ].each do |n|
      PrecinctAlias.find_or_create_by(census_precinct_id: cp.id, name: n)
    end
  end
end
