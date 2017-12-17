require 'ansi'
require 'digest'

namespace :voters do
  desc 'load voter file dump'
  task load: :environment do
    tsv = ENV['VOTER_FILE'] or fail "VOTER_FILE not set"
    voter_file = VoterFile.find_or_create_by(name: tsv)
    PARTIES = {
      'Republican'   => 1,
      'Democratic'   => 2,
      'Unaffiliated' => 3,
      'Libertarian'  => 4,
    }
    pbar = ::ANSI::Progressbar.new('Voters', 1_700_000, STDERR) # TODO count file??
    pbar.format('Voters: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='
    read_tsv_gz(tsv) do |row|
      checksum = Digest::SHA256.hexdigest(
        row['text_registrant_id'].to_s + row['date_of_registration'].to_s + row['date_of_birth'].to_s
      )
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
        v.party = PARTIES[row['desc_party']]
        v.reg_date = row['date_of_registration']
        v.county = row['db_logid']
        v.voter_files = {}
        v.election_codes = {}
        v.voter_files[voter_file.id] = true
        v.phone = "#{row['text_phone_area_code']}-#{row['text_phone_exchange']}-#{row['text_phone_last_four']}"
      end

      if !voter.voter_files[voter_file.id]
        voter.voter_files[voter_file.id] = true
      end

      election_codes.uniq.each do |ec|
        voter.election_codes[election_code(ec).id] = true
      end

      voter.save!

      pbar.inc
    end
    pbar.finish
  end

  def election_code(ec)
    @_election_codes ||= {}
    @_election_codes[ec] ||= ElectionCode.find_or_create_by(name: ec)
  end
end
