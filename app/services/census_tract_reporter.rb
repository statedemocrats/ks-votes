require 'ansi'
require 'election_reporter'

class CensusTractReporter < ElectionReporter
  attr_reader :ct

  def reported
    ct.precinct
  end

  def self.all_by_year
    report = {legend: legend}
    pbar = ::ANSI::Progressbar.new('Precincts', Precinct.count, STDOUT)
    pbar.format('Tracts: %3d%% %s %s', :percentage, :bar, :stat)
    pbar.bar_mark = '='
    seen = {}
    # since our map is 2012 we use only those tracts
    CensusTract.where(year: '2012').find_in_batches do |tracts|
      tracts.each do |ct|
        map_id = ct.map_id
        if seen[map_id]
          STDERR.puts "Dupe map_id #{map_id} for #{ct.id}"
          next
        end
        seen[map_id] = true

        rep = new(ct).by_year
        rep.delete(:legend) # one legend for entire report
        report[map_id] = rep
        pbar.inc
      end
    end
    pbar.finish
    redistribute(report)
    report
  end

  def initialize(ct)
    @ct = ct
  end
end
