require 'csv'
require 'pp'

namespace :openelections do

  desc 'load files for year'
  task load_files: :environment do
    year = ENV['YEAR']
    dir = '../openelections-data-ks/' + year + '/'
    puts "Loading files for #{year} from #{dir}"
    if !Dir.exists?(dir)
      raise "Can't find dir #{dir}"
    end

    Dir.glob(dir + '*.csv').each do |file|
      puts "#{file}"
      load_csv_file(file)
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
    CSV.foreach(file, headers: true) do |row|
      pp(row) if debug?
      county = County.find_or_create_by(name: row['county']) do |c|
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
      results = Result.create(
        votes: row['votes'], 
        precinct: precinct,
        office: office,
        election: election,
        candidate: candidate,
        election_file: election_file,
      )
      
    end
  end   
end
