class PrecinctReporter
  attr_reader :precinct

  PARTY_LABELS = {
    democratic: :d,
    republican: :r,
    reform:     :rf,
    libertarian: :lb,
    indepedent: :in,
    write_in:   :w,
  }.freeze

  KEY_LEGEND = {
    P: :parties,
    T: :total,
    V: :votes,
    PC: :percent,
    S: :stats,
    M: :max,
    pcm: :percent_of_max,
    m: :margin,
    w: :winner,
  }.freeze

  def self.all_by_year
    report = {legend: legend}
    Precinct.find_in_batches do |precincts|
      precincts.each do |p|
        r = new(p).by_year
        r.delete(:legend) # one legend for entire report
        #puts p.map_id
        #puts r.inspect
        report[p.map_id] = r
      end
    end
    report
  end

  def initialize(precinct)
    @precinct = precinct
  end

  def party_abbr(candidate)
    PARTY_LABELS[candidate.party.name] || 'U'
  end

  def self.legend
    KEY_LEGEND.merge(parties: PARTY_LABELS.invert)
  end

  def by_year(year=nil)
    # for all the races in a given year or years,
    # calculate the totals for each office and the spread
    # between the top two candidates.
    report = {S: {M: 0}, legend: self.class.legend}
    precinct.results.full.each do |r|
      next if year and r.election.date.year != year.to_i

      next if r.office.name == ''

      if !r.election
        puts "No election for #{r.inspect}"
        next
      end

      k = [r.election.name, r.office.name, r.office.district].join('::')
      report[k] ||= {T: 0, P: {}}
      party = party_abbr(r.candidate)
      report[k][:P][party] ||= {V: 0, PC: 0}
      report[k][:P][party][:V] += r.votes
      report[k][:T] += r.votes
      report[:S][:M] = report[k][:T] if report[k][:T] > report[:S][:M]
    end
    # compute percentages
    report.each do |k, v|
      next if k == :S
      next if k == :legend
      v[:pcm] = (v[:T].fdiv(report[:S][:M]) * 100).round(1)
      v[:P].each do |n, party_rep|
        # percentage of votes *available* (max) not total (since some races are un-opposed)
        party_rep[:PC] = (party_rep[:V].fdiv(report[:S][:M]) * 100).round(1)
        party_rep[:PC] = 0.0 if party_rep[:PC].nan?
      end
      sorted_parties = v[:P].sort { |a, b| b[1][:PC] <=> a[1][:PC] }
      if sorted_parties.length > 1
        p1 = sorted_parties[0]
        p2 = sorted_parties[1]
        v[:m] = (p1[1].dig(:PC) - p2[1].dig(:PC)).round(1)
      else
        v[:m] = 100
      end
      v[:w] = sorted_parties[0][0]
    end

    report
  end
end