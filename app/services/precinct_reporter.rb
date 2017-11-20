require 'ansi'
require 'election_reporter'

class PrecinctReporter < ElectionReporter
  attr_reader :precinct

  def reported
    precinct
  end

  def self.all_by_year
    report = {legend: legend}
    pbar = ::ANSI::Progressbar.new('Precincts', Precinct.count, STDOUT)
    pbar.format('Precincts: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='
    seen = {}
    Precinct.find_in_batches do |precincts|
      precincts.each do |p|
        next unless p.census_tract_id # for now, skip those without 1:1 mapping

        next unless p.map_id.length > 0

        if seen[p.map_id]
          STDERR.puts "Dupe map_id #{p.map_id} for #{p.id}"
          next
        end
        seen[p.map_id] = true

        r = new(p).by_year
        r.delete(:legend) # one legend for entire report
        #puts p.map_id
        #puts r.inspect
        report[p.map_id] = r
        pbar.inc
      end
    end
    pbar.finish
    report
  end

  def initialize(precinct)
    @precinct = precinct
  end
end
