require 'csv'
require 'digest'
require 'pp'

namespace :openelections do

  desc 'load files for year'
  task load_files: :environment do
    year = ENV['YEAR']
    oe_dir = ENV['OE_DIR'] or raise 'OE_DIR required'

    year.split(/\ *,\ */).each do |y|
      dir = oe_dir + y + '/'
      puts "Loading files for #{y} from #{dir}"
      if !Dir.exists?(dir)
        raise "Can't find dir #{dir}"
      end

      Dir.glob(dir + '*precinct.csv').sort.each do |file|
        next if file.match(/(president|general)__precinct/) # 2012 e.g.
        puts "#{file}"
        if clean?
          clean_csv_file(file)
        else
          load_csv_file(file)
        end
      end
    end
  end

  desc 'load single file'
  task load_file: :environment do
    if clean?
      clean_csv_file(ENV['FILE'])
    else
      load_csv_file(ENV['FILE'])
    end
  end

  def debug?
    ENV['DEBUG'] == '1'
  end

  def clean?
    ENV['CLEAN'] == '1'
  end

  def test_precinct_finder?
    ENV['TEST_PRECINCTS'] == '1'
  end

  def clean_csv_file(file)
    csv_has_headers = false
    CSV.open("#{file}.clean", 'wb') do |csv|
      CSV.foreach(file, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
        csv << row.headers unless csv_has_headers
        csv_has_headers = true
        votes = row['votes'] || row['vote'] || row['poll'] || row['total']
        if !row['precinct'] || !votes || votes.match(/\D/)
          puts "Missing votes or precinct: #{row.inspect}"
          next
        end

        if row['precinct'] == 'TOTAL' || row['precinct'] == 'TOTALS'
          puts "Summary row: #{row.inspect}"
          next
        end

        csv << row
      end # read
    end # write
    # strip trailing newline
    system("truncate -s -1 #{file}.clean")
  end

  def county_tracts
    @_tracts ||= precinct_finder.county_tracts
  end

  def precinct_finder
    @_finder ||= PrecinctFinder.new
  end

  def find_county(name)
    @_counties ||= {}
    @_counties[name.downcase] ||= County.where('lower(name) = ?', name.downcase).first
  end

  def find_tract_by_vtd(vtd_code)
    @_tracts_by_vtd ||= {}
    @_tracts_by_vtd[vtd_code] ||= CensusTract.find_by(vtd_code: vtd_code)
  end

  def load_csv_file(file)
    el_date, state, which, cty, prc = File.basename(file).split('__')
    el_dt = DateTime.strptime("#{el_date}T000000", '%Y%m%dT%H%M%S')
    election = Election.find_or_create_by(name: "#{el_dt.year} #{which}") do |e|
      e.date = el_dt.to_date
    end
    election_file = ElectionFile.find_or_create_by(name: File.basename(file))

    CSV.foreach(file, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
      Rails.logger.debug('new row')
      pp(row) if debug?

      # some required fields
      missing_field = false
      ['county', 'candidate', 'precinct'].each do |field|
        if !row[field]
          puts "No #{field} value in row: #{row.inspect}"
          missing_field = true
        end
      end
      next if missing_field

      next if row['county'] == 'COUNTY'

      votes = row['votes'] || row['vote'] || row['poll'] || row['total']
      if !votes
        puts "Missing votes in row: #{row.inspect}"
        next
      end

      next if row['candidate'].match(/^(Ballots Cast|Registered)$/)
      next if row['candidate'].match(/^(Blank Votes|Over Votes)$/)

      unless county = find_county(row['county'].downcase)
        puts "Can't find county for #{row.inspect}"
        next
      end

      # if VTD is present, trust it to determine precinct
      precinct = nil
      if row['vtd']
        census_tract = find_tract_by_vtd(row['vtd'])
        precinct = census_tract.precinct if census_tract
      end

      # find a reasonable precinct name
      precinct_name = row['precinct']
      precinct ||= precinct_finder.precinct_for_county!(county, precinct_name, election_file)

      # create a PrecinctAlias if the name we were given is not the normalized name
      if precinct.name != precinct_name
        PrecinctAlias.find_or_create_by(name: precinct_name, precinct_id: precinct.id)
      end

      # FIXME ugly hack for what seems to be a JoCo re-use of name for different precincts
      if county.name == 'Johnson'
        if el_dt.year.to_i >= 2016
          if precinct_name == 'Leawood 2-07'
            precinct = Precinct.find_by!(name: 'Leawood 3-01', county_id: county.id)
          elsif precinct_name == 'Leawood 3-01'
            precinct = Precinct.find_by!(name: 'Leawood 3-04 H20', county_id: county.id)
          end
        end
      end 

      puts "raw #{row['precinct']} baked #{precinct_name} precinct_id #{precinct.id}" if debug?

      office = find_office(row['office'], row['district'], election_file.id)
      party = find_party((row['party'] || '').downcase, election_file.id)
      candidate = Candidate.find_or_create_by(name: row['candidate'], party_id: party.id, office_id: office.id) do |c|
        c.election_file_id = election_file.id
      end
      checksum = Digest::SHA256.hexdigest(
        [precinct.name, office.name, election.name, candidate.name, votes, election_file.name].join(':')
      )

      next if test_precinct_finder?

      result = Result.find_or_create_by(checksum: checksum) do |r|
        r.votes = votes
        r.precinct = precinct
        r.office = office
        r.election = election
        r.candidate = candidate
        r.election_file = election_file
      end
      
    end
  end

  def find_office(office_name, district_name, election_file_id)
    @_offices ||= {}
    k = "#{office_name},#{district_name}"
    @_offices[k] ||= Office.find_or_create_by(name: office_name, district: district_name) do |o|
      o.election_file_id = election_file_id
    end
  end

  def find_party(party_name, election_file_id)
    @_parties ||= {}
    @_parties[party_name] ||= Party.find_or_create_by(name: party_name) do |p|
      p.election_file_id = election_file_id
    end
  end
end
