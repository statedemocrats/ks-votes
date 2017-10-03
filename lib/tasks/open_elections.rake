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

  def county_tracts
    @_tracts ||= begin
      County.all.map { |cty| [cty.name, cty.census_tracts.pluck(:name, :id).to_h ] }.to_h
    end
  end

  def precinct_for_county(county, precinct_name, election_file)
    orig_precinct_name = precinct_name

    # common clean up first since we'll create from this string
    precinct_name = precinct_name.strip
      .gsub(/\ \ +/, ' ')
      .gsub(' / ', '/')
      .gsub(/\btwp\b/i, 'Township')

    #puts "Orig precinct '#{orig_precinct_name}' cleaned '#{precinct_name}'"

    # check cache of tract names
    census_tract_id = county_tracts.dig(county.name, precinct_name)

    # if we can't find an exact name match on precinct and census_tract,
    # we'll start to permutate the name to try and find a match.
    if !census_tract_id
      # first, look in the known aliases
      pa = PrecinctAlias.find_by(name: orig_precinct_name)
      if pa && pa.precinct.county_id == county.id
        precinct_name = pa.precinct.name
        census_tract_id = pa.precinct.census_tract_id # might be null, that's ok.
      
      # no alias? look for common permutations
      elsif county_tracts.dig(county.name, "#{precinct_name} Township")
        precinct_name += ' Township'
      elsif county_tracts.dig(county.name, precinct_name.gsub(/\btwp\b/i, 'Township'))
        precinct_name.gsub!(/\btwp\b/i, 'Township')
      elsif precinct_name.match(/twp$/i)
        maybe_precinct_name = precinct_name.sub(/twp$/i, 'Township')
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
      elsif precinct_name.match(/twp [\-\d]+$/)
        maybe_precinct_name = precinct_name.sub(/twp ([\d\-]+)$/i, 'Township Precinct \1')
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
      elsif precinct_name.match(/\w, \w/)
        parts = precinct_name.split(', ')
        maybe_precinct_name = parts[1] + ' ' + parts[0]
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
      elsif precinct_name.match(/^[A-Z\d\ ]+$/)
        maybe_precinct_name = precinct_name.titlecase
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
      elsif precinct_name.match(/\ 0(\d)/)
        # strip leading zero
        maybe_precinct_name = precinct_name.gsub(/\ 0(\d)/, ' \1')
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)

      # MUST be last
      elsif precinct_name.match(/Precinct/)
        maybe_precinct_name = precinct_name.sub(/^.+?Precinct/, 'Precinct')
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
      end 
    end 

    # if we still don't have a census_tract, try again with the altered name.
    census_tract_id ||= county_tracts.dig(county.name, precinct_name) || nil

    # finally, create a Precinct if we must.
    if !census_tract_id
      precinct = Precinct.find_or_create_by(county_id: county.id, name: precinct_name) do |p|
        p.election_file_id = election_file.id
      end
      if orig_precinct_name != precinct_name && !precinct.has_alias?(orig_precinct_name)
        puts "Aliasing #{orig_precinct_name} -> #{precinct_name}"
        PrecinctAlias.create(name: orig_precinct_name, precinct_id: precinct.id)
      end
      return precinct
    else
      # census_tract.name == precinct_name but Precinct might not yet exist.
      # NOTE we do NOT pass in census_precinct_id to create a new Precinct since we trust it is
      # *NOT* the primary precinct for the census tract (in which case we would have found it above).
      precinct = Precinct.find_or_create_by(county_id: county.id, name: precinct_name)
      CensusPrecinct.find_or_create_by(precinct_id: precinct.id, census_tract_id: census_tract_id)
      return precinct
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

      next if row['candidate'].match(/^(Ballots Cast|Registered)$/)
      next if row['candidate'].match(/^(Blank Votes|Over Votes)$/)

      # these are often summary or informational rows,
      # unhelpfully, interspersed with actual precinct totals.
      if !row['precinct'] || !votes || votes.match(/\D/) # && !row['office']
        puts "Missing precinct or votes in row: #{row.inspect}"
        next
      end

      county = County.where('lower(name) = ?', row['county'].downcase).first_or_create(
        name: row['county'], election_file_id: election_file.id
      )

      # find a reasonable precinct name
      precinct_name = row['precinct']
      precinct = precinct_for_county(county, precinct_name, election_file)

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
