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
        load_csv_file(file)
      end
    end
  end

  desc 'load single file'
  task load_file: :environment do
    load_csv_file(ENV['FILE'])
  end

  def debug?
    ENV['DEBUG'] == '1'
  end

  def load_csv_file(file)
    el_date, state, which, cty, prc = File.basename(file).split('__')
    el_dt = DateTime.strptime("#{el_date}T000000", '%Y%m%dT%H%M%S')
    election = Election.find_or_create_by(date: el_dt.to_date, name: "#{el_dt.year} #{which}")
    election_file = ElectionFile.find_or_create_by(name: File.basename(file))
    CSV.foreach(file, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
      pp(row) if debug?
      pp(row.headers()) if debug?
      if !row['county']
        puts "No county value in row: #{row.inspect}"
        next
      end
      votes = row['votes'] || row['vote'] || row['poll'] || row['polls']

      # these are often summary or informational rows,
      # unhelpfully, interspersed with actual precinct totals.
      if !row['precinct'] || !votes # && !row['office']
        puts "Missing precinct or votes in row: #{row.inspect}"
        next
      end

      county = County.find_or_create_by(name: row['county'].titlecase) do |c|
        c.election_file_id = election_file.id
      end
      precinct = Precinct.find_or_create_by(county_id: county.id, name: row['precinct']) do |p|
        p.election_file_id = election_file.id
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
