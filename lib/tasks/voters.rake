require 'ansi'
require 'digest'

namespace :voters do
  desc 'load voter file dump'
  task load: :environment do
    tsv = ENV['VOTER_FILE'] or fail "VOTER_FILE not set"
    voter_file = VoterFile.find_or_create_by(name: tsv)
    pbar = ::ANSI::Progressbar.new('Voters', 1_800_000, STDERR) # TODO count file??
    pbar.format('Voters: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='

    Voter.transaction do
      read_tsv_gz(tsv) do |row|
        county = row['db_logid'].strip
        name = [row['text_name_first'], row['text_name_middle'], row['text_name_last']].compact.map(&:strip).join(' ')
        addr = [row['text_res_address_nbr'], row['text_street_name'], row['text_res_city'], row['text_res_zip5'], county].compact.map(&:strip).join(';')
        checksum = Digest::SHA256.hexdigest( row['text_registrant_id'].to_s )
        districts = {}
        election_codes = []
        row.each do |k,v|
          next unless k && v
          next unless v.match(/\S/)
  
          if k.match(/^district_/)
            districts[k.sub(/^district_/, '')] = v
          elsif k.match(/^text_election_code/)
            election_codes << v
          end
        end
        voter = Voter.find_or_create_by(checksum: checksum) do |v|
          [
            'name_first',
            'name_middle',
            'name_last',
            'res_address_nbr',
            'res_address_nbr_suffix',
            'street_name',
            'res_unit_nbr',
            'res_city',
            'res_zip5',
            'res_zip4',
            'res_carrier_rte'
          ].each do |f|
            key = 'text_' + f
            next unless row[key]
            v[f] = row[key].strip
          end
          if row['cde_street_type']
            street_suffix = ['cde_street_dir_prefix', 'cde_street_type', 'cde_street_dir_suffix'].map { |k| row[k] }.compact.join(' ')
            v.street_name ||= ''
            v.street_name += ' ' + street_suffix
          end
          v.districts = districts
          v.dob = row['date_of_birth']
          v.ks_voter_id = row['text_registrant_id']
          v.precinct = row['precinct_part_text_name']
          v.party_history = {}
          v.party_history[row['date_of_registration']] = Voter::PARTIES[row['desc_party']]
          v.county = county
          v.voter_files = {}
          v.election_codes = {}
          v.voter_files[voter_file.id] = { dob: row['date_of_birth'], name: name, addr: addr }
          v.phone = "#{row['text_phone_area_code']}-#{row['text_phone_exchange']}-#{row['text_phone_last_four']}"
        end
  
        if !voter.voter_files[voter_file.id]
          voter.voter_files[voter_file.id] = {
            dob: row['date_of_birth'],
            name: name,
            addr: addr,
            status: row['cde_registrant_status'].strip,
            party: row['desc_party'],
          }
        end
  
        election_codes.uniq.each do |ec|
          voter.election_codes[election_code(ec).id] = true
        end

        # bad upstream data means reg date does not always change when party changes.
        # so rely more on voter_files.party for changes.
        voter.party_history[row['date_of_registration']] = Voter::PARTIES[row['desc_party']]
  
        voter.save!
  
        pbar.inc
      end
    end
    pbar.finish
  end

  task vtds: :environment do
    election_file = ElectionFile.find_or_create_by(name: 'vtd_matcher_no_such_file')
    voters = Voter.where(vtd: nil)
    if ENV['COUNTY']
      voters = voters.where(county: ENV['COUNTY'])
    end
    pbar = ::ANSI::Progressbar.new('Voters', voters.count, STDERR)
    pbar.format('Voter VTDs: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='
    Voter.transaction do
      voters.find_in_batches do |voters|
        voters.each do |voter|
          pbar.inc
          if voter.district_pt
            voter.update_column(:vtd, voter.district_pt)
          elsif voter.precinct
            info = precinct_finder.precinct_for_county(find_county(voter.county), voter.precinct, election_file)
            precinct = info[:precinct]
            if !precinct
              puts "No precinct found for #{voter.id} #{blue(voter.precinct)}"
              next
            end
            next unless precinct.census_tract
            voter.update_column(:vtd, precinct.census_tract.vtd_code)
          end
        end
      end
    end
    pbar.finish
  end

  task address_csv: :environment do
    voter_count = Voter.count
    pbar = ::ANSI::Progressbar.new('Voters', voter_count, STDERR)
    pbar.format('Voters: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='
    seen_addresses = {}
    file = 'public/voter-addresses.csv'
    CSV.open(file, 'wb') do |csv|
      Voter.find_in_batches do |voters|
        voters.each do |voter|
          pbar.inc
          next unless voter.res_address_nbr && voter.street_name && voter.res_zip5 && voter.res_city

          street = voter.res_address_nbr.strip + ' ' + voter.street_name.strip
          street.gsub!(/\ +/, ' ')
          city = voter.res_city.strip
          zip = voter.res_zip5.strip
          sha = Digest::SHA256.hexdigest([street,city,zip].join(' '))
          seen_addresses[sha] ||= 0
          seen_addresses[sha] += 1
          next if seen_addresses[sha] > 1

          csv << [sha, street, city, 'KS', zip]
        end
      end
    end
    pbar.finish
    puts "File written to #{file}"
  end

  def election_code(ec)
    @_election_codes ||= {}
    @_election_codes[ec] ||= ElectionCode.find_or_create_by(name: ec)
  end

  task count: :environment do
    County.order('name').all.each do |county|
      county_voters = Voter.where(county: county.name).count
      puts "#{county.name} #{county_voters}"
      county.census_tracts.each do |ct|
        counts = ct.voters.count
        puts "  >>  #{ct.name} = #{counts}"
      end
    end
  end

  task count_county: :environment do
    county = County.l(ENV['COUNTY'])
    county_voters = Voter.where(county: county.name).count
    puts "#{county.name} #{county_voters}"
    county.census_tracts.each do |ct|
      counts = ct.voters.count
      puts "  >>  #{ct.name} = #{counts}"
    end
  end

  task precinct_stats: :environment do
    precinct = ENV['PRECINCT']
    county = ENV['COUNTY']
    reporter = VoterReporter.new(County.l(county))
    report = reporter.precincts
    precinct = Precinct.find(precinct)
    stats = report[precinct.census_tract.map_id]
    stats.keys.sort.each do |election|
      print election
      stats[election].keys.sort.each do |party|
        count = stats[election][party][:c]
        percentage = stats[election][party][:p]
        printf(" | %s %d %0.1f%%", party, count, percentage)
      end
      puts " |"
    end
  end

  task county_stats: :environment do
    county = ENV['COUNTY']
    reporter = VoterReporter.new(County.l(county))
    report = reporter.precincts
    file = "public/#{county.downcase}-county-voters-stats.json"
    File.write(file, report.to_json)
    puts "Stats written to #{file}"
  end
end
