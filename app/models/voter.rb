class Voter < VoterFileBase

  PARTIES = {
    'Republican'   => 1,
    'Democratic'   => 2,
    'Unaffiliated' => 3,
    'Libertarian'  => 4,
  }

  PARTIES_BY_ID = PARTIES.invert

  def name
    [name_first, name_middle, name_last].compact.join(' ')
  end

  def district_pt
    districts['pt']
  end

  def party_for_election(election_name)
    return unless election_name.match(/\d+/)
    year = election_name.match(/(\d+)/)[1]
    party = nil
    party_history_sorted.each do |tuple|
      ymd, party_name, date = tuple
      #puts "#{ymd} #{party_name} ?? #{year}"
      next if date.year > year.to_i # registration after election
      party = party_name
      break
    end
    party
  end

  def party_recent
    party_history_sorted.first[1]
  end

  def party_history_sorted
    history = []
    party_history.each do |mdy, party_id|
      party = PARTIES_BY_ID[party_id.to_i]
      date = Date.strptime(mdy, '%m/%d/%Y')
      history << [date.strftime('%F'), party, date]
    end
    history.sort {|a, b| b[0] <=> a[0] }
  end
end
