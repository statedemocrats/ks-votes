require 'ansi'
require 'digest'

namespace :voters do
  desc 'load voter file dump'
  task load: :environment do
    tsv = ENV['VOTER_FILE'] or fail "VOTER_FILE not set"
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
      name = [row['text_name_first'], row['text_name_middle'], row['text_name_last']].compact.join(' ')
      addr = [row['text_res_address_nbr'], row['text_street_name'], row['text_res_city'], row['text_res_zip5']].compact.join(' ')
      checksum = Digest::SHA256.hexdigest(name + row['date_of_birth'] + addr)
      districts = {}
      row.each do |k,v|
        next unless k && v
        next unless k.match(/^district_/)
        next unless v.match(/\S/)
        districts[k.sub(/^district_/, '')] = v
      end
      voter = Voter.find_or_create_by(checksum: checksum) do |v|
        [
          'name_first',
          'name_middle',
          'name_last',
          'res_address_nbr',
          'res_address_nbr_suffix',
          'res_street_name',
          'res_unit_nbr',
          'res_city',
          'res_zip5',
          'res_zip4',
          'res_carrier_rte'
        ].each do |f|
          v[f] = row['text_' + f]
        end
        v.districts = districts
        v.dob = row['date_of_birth']
        v.ks_voter_id = row['text_registrant_id']
        v.precinct = row['precinct_part_text_name']
        v.party = PARTIES[row['desc_party']]
        v.reg_date = row['date_of_registration']
        v.file_name = tsv
      end

      pbar.inc
    end
    pbar.finish
  end
end
