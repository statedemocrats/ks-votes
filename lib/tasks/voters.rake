require 'ansi'
require 'digest'

namespace :voters do
  desc 'load voter file dump'
  task load: :environment do
    tsv = ENV['VOTER_FILE'] or fail "VOTER_FILE not set"
    voter_file = VoterFile.find_or_create_by(name: tsv)
    pbar = ::ANSI::Progressbar.new('Voters', 1_780_000, STDERR) # TODO count file??
    pbar.format('Voters: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='

    Voter.transaction do
      read_tsv_gz(tsv) do |row|
        name = [row['text_name_first'], row['text_name_middle'], row['text_name_last']].compact.join(' ')
        addr = [row['text_res_address_nbr'], row['text_street_name'], row['text_res_city'], row['text_res_zip5']].compact.join(';')
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
            v[f] = row[key]
          end
          v.districts = districts
          v.dob = row['date_of_birth']
          v.ks_voter_id = row['text_registrant_id']
          v.precinct = row['precinct_part_text_name']
          v.party_history = {}
          v.party_history[row['date_of_registration']] = Voter::PARTIES[row['desc_party']]
          v.county = row['db_logid']
          v.voter_files = {}
          v.election_codes = {}
          v.voter_files[voter_file.id] = { dob: row['date_of_birth'], name: name, addr: addr }
          v.phone = "#{row['text_phone_area_code']}-#{row['text_phone_exchange']}-#{row['text_phone_last_four']}"
        end
  
        if !voter.voter_files[voter_file.id]
          voter.voter_files[voter_file.id] = { dob: row['date_of_birth'], name: name, addr: addr }
        end
  
        election_codes.uniq.each do |ec|
          voter.election_codes[election_code(ec).id] = true
        end
  
        voter.party_history[row['date_of_registration']] = Voter::PARTIES[row['desc_party']]
  
        voter.save!
  
        pbar.inc
      end
    end
    pbar.finish
  end

  def election_code(ec)
    @_election_codes ||= {}
    @_election_codes[ec] ||= ElectionCode.find_or_create_by(name: ec)
  end

  def election_code_by_id(id)
    @_election_codes_by_id ||= {}
    @_election_codes_by_id[id] ||= ElectionCode.find(id)
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
    voters = Voter.where(county: county).where(precinct: precinct)
    stats = {}
    voter_count = 0
    party_counts = {}
    voters.find_in_batches do |vs|
      vs.each do |voter|
        voter_count += 1
        party = voter.party_recent
        party_counts[party] ||= 0
        party_counts[party] += 1
        # might change party between elections, so for each year, find
        # the most recent party affiliation
        voter.election_codes.keys.each do |election_code_id|
          ec = election_code_by_id(election_code_id)
          election = ec.name
          party = voter.party_for_election(election)
          if !party
            # voter was not registered for this election
            next
          end
          stats[election] ||= {}
          stats[election][party] ||= 0
          stats[election][party] += 1
        end
      end
    end
    puts "voter_count = #{voter_count}"
    stats.keys.sort.each do |election|
      print election
      stats[election].keys.sort.each do |party|
        count = stats[election][party]
        printf(" | %s %d %0.1f%%", party, count, (count.to_f / party_counts[party]).to_f * 100)
      end
      puts " |"
    end
  end
end
