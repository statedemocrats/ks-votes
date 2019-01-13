class VoterReporter

  attr_reader :county

  def initialize(county)
    @county = county
  end

  def election_code_by_id(id)
    @_election_codes_by_id ||= {}
    @_election_codes_by_id[id] ||= ElectionCode.find(id)
  end

  def election_code(ec)
    @_election_codes ||= {}
    @_election_codes[ec] ||= ElectionCode.find_by(name: ec)
  end

  def precincts
    report = {names: {}}
    election_years = (1900 .. Time.now.year)
    county.census_tracts.each do |ct|
      stats = {}
      voter_count = 0
      party_counts = {}
      ct.each_voter do |voter|
        voter_count += 1
        # use party history as proxy for party registrations,
        # regardless of whether this voter actually voted in a given election.
        election_years.each do |year|
          y = year.to_s
          party = voter.party_for_election(y)
          next unless party
          if voter.voter_files_for_year(y).any? && voter.voter_file_status_in_year(y) != 'A'
            #puts "Skipping election year #{y} for voter #{voter.name} (not active)"
            next
          end
          party_counts[y] ||= { party => 0 }
          party_counts[y][party] ||= 0
          party_counts[y][party] += 1
        end
        # actual election turnout.
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

      #puts "#{voter_count} voters in census tract #{ct.name}"
      #pp party_counts

      stats.keys.sort.each do |election|
        stats[election].keys.sort.each do |party|
          count = stats[election][party]
          election_code = election_code(election)
          registered = party_counts[election_code.year][party]
          stats[election][party] = {
            r: registered,
            c: count,
            p: (count.to_f / registered).to_f * 100
          }
        end
      end

      report[ct.map_id] = stats
      report[:names][ct.name] = ct.map_id

      # all the aliases
      ct.alt_names.each do |n|
        report[:names][n] = ct.map_id
      end
    end

    report
  end
end
