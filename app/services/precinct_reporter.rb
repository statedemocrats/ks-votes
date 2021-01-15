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
    Precinct.find_in_batches do |precincts|
      precincts.each do |p|
        next unless p.census_tract_id # for now, skip those without 1:1 mapping

        next unless p.map_id.length > 0

        r = new(p).by_year
        r.delete(:legend) # one legend for entire report
        #puts p.map_id
        #puts r.inspect
        if report[p.map_id]
          report[p.map_id].merge!(r)
        else
          report[p.map_id] = r
        end
        pbar.inc
      end
    end
    pbar.finish
    redistribute(report)
    report
  end

  def initialize(precinct)
    @precinct = precinct
  end
end
