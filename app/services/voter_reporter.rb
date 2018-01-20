class VoterReporter

  attr_reader :county

  def initialize(county)
    @county = county
  end

  def precincts
    report = {}
    county.census_tracts.each do |ct|
      stats = {}
      voter_count = 0
      party_counts = {}
      ct.voters.find_in_batches do |voters|
        voters.each do |voter|
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
      puts "#{voter_count} voters in census tract #{ct.name}"
      stats.keys.sort.each do |election|
        stats[election].keys.sort.each do |party|
          count = stats[election][party]
          stats[election][party] = { count: count, percentage: (count.to_f / party_counts[party]).to_f * 100 }
        end
      end

      report[ct.map_id] = stats
    end

    report
  end
end
