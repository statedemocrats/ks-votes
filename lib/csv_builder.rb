require 'csv'

class CsvBuilder
  def initialize(elections:, tracts:)
    @elections = elections
    @tracts = tracts
  end

  def to_csv(filepath)
    CSV.open(filepath, "wb") do |csv|
      #csv << ["row", "of", "CSV", "data"]

    #  csv.flush # do not buffer
    end
  end

  private

  attr_reader :elections, :tracts

  def legend
    @legend ||= elections["legend"]
  end

  def precinct_rows
    rows = []
    tracts.entries.each do |precinct|
      props = precinct.properties
      name = props['VTDNAME']
      vtd = props['VTD_S']
      elections_key = props['VTD_2012'] # state + county + vtd
      results = elections[elections_key]
      puts "name:#{name} vtd:#{vtd} elections:#{results.pretty_inspect}"
    end
  end
end
