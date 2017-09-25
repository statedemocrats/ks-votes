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

      Dir.glob(dir + '*precinct.csv').each do |file|
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

  def clean_csv_file(file)
    csv_has_headers = false
    CSV.open("#{file}.clean", 'wb') do |csv|
      CSV.foreach(file, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
        csv << row.headers unless csv_has_headers
        csv_has_headers = true
        votes = row['votes'] || row['vote'] || row['poll'] || row['total']
        if !row['precinct'] || !votes
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

  def county_precincts
    @_precincts ||= begin
      County.all.map { |cty| [cty.name, cty.census_precincts.pluck(:name, :id).to_h ] }.to_h
    end
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
      if !row['county']
        puts "No county value in row: #{row.inspect}"
        next
      end
      votes = row['votes'] || row['vote'] || row['poll'] || row['total']

      # these are often summary or informational rows,
      # unhelpfully, interspersed with actual precinct totals.
      if !row['precinct'] || !votes # && !row['office']
        puts "Missing precinct or votes in row: #{row.inspect}"
        next
      end

      county = County.where('lower(name) = ?', row['county'].downcase).first_or_create(
        name: row['county'], election_file_id: election_file.id
      )

      # find a reasonable precinct name
      precinct_name = row['precinct']
      if !county_precincts.dig(county.name, precinct_name)
        precinct_name += ' Township' if county_precincts.dig(county.name, "#{precinct_name} Township")
        if precinct_name.match(/\w, \w/)
          parts = precinct_name.split(', ')
          maybe_precinct_name = parts[1] + ' ' + parts[0]
          precinct_name = maybe_precinct_name if county_precincts.dig(county.name, maybe_precinct_name)
        end
        if precinct_name.match(/^[A-Z\d\ ]+$/)
          maybe_precinct_name = precinct_name.titlecase
          precinct_name = maybe_precinct_name if county_precincts.dig(county.name, maybe_precinct_name)
        end
      end

      census_precinct_id = county_precincts.dig(county.name, precinct_name) || nil
      puts "raw #{row['precinct']} baked #{precinct_name} census_precinct_id #{census_precinct_id.inspect}" if debug?

      precinct = Precinct.find_or_create_by(county_id: county.id, name: precinct_name) do |p|
        p.election_file_id = election_file.id
        p.census_precinct_id = census_precinct_id if census_precinct_id
      end
      office = Office.find_or_create_by(name: row['office'], district: row['district']) do |o|
        o.election_file_id = election_file.id
      end
      party = Party.find_or_create_by(name: (row['party'] || '').downcase) do |p|
        p.election_file_id = election_file.id
      end
      candidate = Candidate.find_or_create_by(name: row['candidate'], party_id: party.id, office_id: office.id) do |c|
        c.election_file_id = election_file.id
      end
      checksum = Digest::SHA256.hexdigest(
        [precinct.name, office.name, election.name, candidate.name, votes, election_file.name].join(':')
      )
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
end
