class Voter < VoterFileBase

  PARTIES = {
    'Republican'   => 1,
    'Democratic'   => 2,
    'Unaffiliated' => 3,
    'Libertarian'  => 4,
  }

  PARTIES_BY_ID = PARTIES.invert

  VF_STATUS = {
    'A' => :active,
    'I' => :inactive,
    'S' => :suspended,
  }

  def name
    [name_first, name_middle, name_last].compact.join(' ')
  end

  def district_pt
    districts['pt']
  end

  def voter_file_rec(vf_id)
    @@_voter_files ||= {}
    @@_voter_files[vf_id] ||= VoterFile.find(vf_id)
  end

  # sort by date of file
  def voter_files_sorted
    files = []
    voter_files.each do |vf_id,payload|
      vf = voter_file_rec(vf_id)
      ymd = vf.name.match(/(\d{8})/)[1]
      year = ymd.match(/^(\d\d\d\d)/)[1]
      files << { year: year, ymd: ymd, file: vf.name }.merge(payload)
    end
    files.sort {|a, b| b[:ymd] <=> a[:ymd] }
  end

  def recent_voter_file_status
    voter_files_sorted.first['status']
  end

  def voter_file_status_in_year(year)
    voter_files_for_year(year).first['status']
  end

  def voter_files_for_year(year)
    voter_files_sorted.select {|vf| vf[:year] == year }
  end

  def party_for_election(election_name)
    return unless election_name.match(/(19|20)\d\d$/)
    year = election_name.match(/((19|20)\d\d)$/)[1]
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

  # party_history as array, recent first
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
