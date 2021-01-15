require 'csv'
require 'pp'
require 'task_helpers'

module OpenElections
  include TaskHelpers
  include Term::ANSIColor

  SKIP_PRECINCTS = [
    'Absent',
    'Adv/Prov',
    'Advance',
    'Advance Ballots',
    'Advance Voters',
    'Advance Vote',
    'Advanced',
    'Ballots Cast',
    'County Totals',
    'Ent Test',
    'President',
    'Prov',
    'Provisional',
    'Paper Ballots',
    'Registered Voters',
    'Supplemental Votes',
    'Total',
    'Totals',
    'Write-ins',
    'Zzz',
  ].freeze

  def self.clean_csv_file(file)
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

  def self.load_csv_file(file)
    # must create election_file first, as many objects depend upon its existence.
    election_file = ElectionFile.find_or_create_by(name: File.basename(file))

    # if file naming convention ever changes, this date munging will break.
    el_date, state, which, cty, prc = File.basename(file).split('__')
    if which == 'primary' && !ENV['INCLUDE_PRIMARY']
      puts "Skipping #{file} - set INCLUDE_PRIMARY to parse primary results"
      return
    end
    el_dt = DateTime.strptime("#{el_date}T000000", '%Y%m%dT%H%M%S')
    election = Election.find_or_create_by(name: "#{el_dt.year} #{which}") do |e|
      e.date = el_dt.to_date
      e.election_file = election_file
    end

    CSV.foreach(file, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8').with_index(1) do |row, line_num|
      Rails.logger.debug('new row')

      # header row causes the line_num to off-by-one
      line_n = line_num + 1
      if debug?
        puts "Line #{line_n} #{row.inspect}"
      end

      next if !row['office'] or row['office'].match(/^(Ballots Cast|Registered Voters)$/)

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
      next if (row['office'] || '').downcase == 'voters'

      unless county = find_county(row['county'].downcase)
        puts "Can't find county for #{row.inspect}"
        next
      end

      # if VTD is present, trust it to determine precinct
      precinct = nil
      census_tract = nil
      reason = :finder # default
      if row['vtd']
        census_tract = find_tract_by_vtd(row['vtd'], county)
        if census_tract
          precinct = census_tract.precinct
          puts "[#{county.name}] Located precinct #{blue(precinct.name)} via VTD #{row['vtd']}" if debug?
          reason = :vtd
        end
      end

      # find a reasonable precinct name
      precinct_name = row['precinct']

      next if SKIP_PRECINCTS.include? precinct_name.titlecase

      precinct ||= precinct_finder.precinct_for_county!(county, precinct_name, election_file)
      census_tract ||= precinct.census_tract

      # create a PrecinctAlias if the name we were given is not the normalized name
      if !census_tract && precinct.name.downcase != precinct_name.downcase && !precinct.has_alias?(precinct_name)
        puts "[#{county.name}] Aliasing PrecinctFinder result: #{red(precinct_name)} -> #{red(precinct.name)}"
        PrecinctAlias.find_or_create_by(name: precinct_name, precinct_id: precinct.id) do |pa|
          pa.reason = :finder
        end
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

      puts "raw #{blue(row['precinct'])} baked #{blue(precinct.name)} precinct_id #{precinct.id}" if debug?

      office = find_office((row['office'] || ''), (row['district'] || ''), election_file.id)
      party = find_party((row['party'] || ''), election_file.id)
      candidate = Candidate.find_or_create_by(name: row['candidate'], party_id: party.id, office_id: office.id) do |c|
        c.election_file_id = election_file.id
      end

      checksum = line_n.to_s + ':' + election_file.name

      next if test_precinct_finder?

      result = Result.find_or_create_by(checksum: checksum) do |r|
        r.votes = votes
        r.precinct = precinct
        r.office = office
        r.election = election
        r.candidate = candidate
        r.election_file = election_file
        r.reason = reason
      end

      if debug?
        pp result
      end

    end
  end
end
