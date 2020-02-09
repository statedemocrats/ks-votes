require 'csv'

class CsvBuilder
  def initialize(elections:, tracts:, counties:)
    @elections = elections
    @tracts = tracts
    @counties = counties
  end

  def to_csv(filepath)
    row_count = 0
    CSV.open(filepath, "wb") do |csv|
      csv << header
      precinct_rows.each do |row|
        csv << header.map { |colname| row[colname] }
        row_count += 1
      end
    #  csv.flush # do not buffer
    end
    row_count
  end

  def header
    @header ||= build_header
  end

  private

  attr_reader :elections, :tracts, :counties

  def legend
    @legend ||= elections["legend"]
  end

  # unwind the entire legend
  def build_header
    header = [
      :county,
      :vtdname,
      :vtd,
      :fips,
      :area,
      :population,
      :id,
      :geosha,
      :fuzzy_boundary
    ]
    legend.dig("races", "elections").each do |election_id, election|
      legend.dig("races", "offices").each do |office_id, office|
        race = [election, office["n"], office["d"]].reject(&:empty?).join(" ")
        header << "#{race} Ballots"
        header << "#{race} Winner"
        legend.dig("parties").each do |party_key, party_name|
          party = party_name.titlecase
          header << "#{race} #{party} Votes"
          header << "#{race} #{party} %"
        end
      end
    end
    header
  end

  def precinct_rows
    tracts["features"].map do |precinct|
      props = precinct["properties"]
      name = props['VTDNAME']
      vtd = props['VTD_S']
      elections_key = props['VTD_2012'] # state + county + vtd
      county_fips = elections_key.match(/^..(...)/)[1]
      results = elections[elections_key]
      #puts "name:#{name} vtd:#{vtd} elections:#{results.pretty_inspect}"
      row = {
        county: counties[county_fips],
        vtdname: name,
        vtd: vtd,
        fips: elections_key,
        area: props['DATA'],
        population: props['POPULATION'],
        id: props['ID'],
        geosha: props['geosha']
      }
      next unless results
      results.each do |key, votes|
        if key =~ /:/
          election_id, office_id = key.split(":")
          election = legend.dig("races", "elections", election_id)
          office = legend.dig("races", "offices", office_id)
          office_name = office["n"]
          office_district = office["d"]
          #puts "election:#{election} office_name:#{office_name} district:#{office_district} votes:#{votes}"
          race = [election, office_name, office_district].reject(&:empty?).join(" ")
          #pp votes
          row["#{race} Ballots"] = votes["T"]
          row[:fuzzy_boundary] = votes["f"].present?
          row["#{race} Winner"] = legend.dig("parties", votes["w"])&.titlecase
          votes["P"].each do |party_key, vp|
            party = legend.dig("parties", party_key)&.titlecase
            row["#{race} #{party} Votes"] = vp["V"]
            row["#{race} #{party} %"] = vp["PC"]
          end
        else
          #puts "else:#{key} votes:#{votes.pretty_inspect}"
        end
      end
      row
    end.compact
  end
end
