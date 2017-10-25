class PrecinctReporter
  attr_reader :precinct

  def self.all_by_year
    report = {}
    Precinct.find_in_batches do |precincts|
      precincts.each do |p|
        report[p.county.name] ||= {}
        # TODO better unique identifier than p.name
        # make geojson lookup fast.
        report[p.county.name][p.name] = new(p).by_year
      end
    end
    report
  end

  def initialize(precinct)
    @precinct = precinct
  end

  def by_year(year=nil)
    # for all the races in a given year or years,
    # calculate the totals for each office and the spread
    # between the top two candidates.
    report = {stats: {max: 0}}
    precinct.results.full.each do |r|
      next if year and r.election.date.year != year.to_i

      next if r.office.name == ''

      if !r.election
        puts "No election for #{r.inspect}"
        next
      end

      k = [r.election.name, r.office.name, r.office.district].join('::')
      report[k] ||= {total: 0, parties: {}}
      report[k][:parties][r.candidate.party.name] ||= {votes: 0, percent: 0}
      report[k][:parties][r.candidate.party.name][:votes] += r.votes
      report[k][:total] += r.votes
      report[:stats][:max] = report[k][:total] if report[k][:total] > report[:stats][:max]
    end
    # compute percentages
    report.each do |k, v|
      next if k == :stats
      v[:percent_of_max] = (v[:total].fdiv(report[:stats][:max]) * 100).round(1)
      v[:parties].each do |n, rep|
        # percentage of votes *available* (max) not total (since some races are un-opposed)
        rep[:percent] = (rep[:votes].fdiv(report[:stats][:max]) * 100).round(1)
        rep[:percent] = 0.0 if rep[:percent].nan?
      end
      #pp v[:parties]
      sorted_parties = v[:parties].sort { |a, b| b[1][:percent] <=> a[1][:percent] }
      if sorted_parties.length > 1
        v[:margin] = (sorted_parties[0][1].dig(:percent) - sorted_parties[1][1].dig(:percent)).round(1)
      else
        v[:margin] = 100
      end
      v[:winner] = sorted_parties[0][0]
    end

    report
  end
end
