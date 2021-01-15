# given a county and a year, quick lookup by precinct name
class CountyTractMatcher
  include Term::ANSIColor
  extend Term::ANSIColor

  def self.create_memos
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    @@counties = County.all.map { |cty| [cty.id, cty.name] }.to_h
    @@county_tracts = {}
    County.all.each do |cty|
      tract_hash = {}
      cty.census_tracts.pluck(:year, :name, :id).each do |tuple|
        tract_hash[tuple[0]] ||= {}
        tract_hash[tuple[0]][tuple[1]] = tuple[2]
      end
      @@county_tracts[cty.name] = tract_hash
    end
    PrecinctAlias.curated.includes(:precinct).order(:created_at).each do |pa|
      cty_name = @@counties[pa.precinct.county_id]
      cti = pa.precinct.census_tract_id
      year = cti ? pa.precinct.year : nil
      existing_cti = @@county_tracts.dig(cty_name, year, pa.name)
      if existing_cti
        puts "[#{cty_name}] PrecinctAlias #{green(pa.name)} #{blue(pa.precinct.name)} #{cti} pre-defined as #{existing_cti}"
        next # TODO overwrite??
      end
      @@county_tracts[cty_name][year] ||= {}
      @@county_tracts[cty_name][year][pa.name] = cti
    end
    ActiveRecord::Base.logger = old_logger
  end

  create_memos # call on init

  def self.county_tracts
    @@county_tracts
  end

  def match(county_name, election_year, precinct_name)
    found = @@county_tracts.dig(county_name, election_year, precinct_name)
    return found if found

    @@county_tracts.dig(county_name).each do |year, precincts|
      found = precincts.dig(precinct_name)
      return found if found
    end

    nil # no match
  end

  def tracts_for(county_name)
    @@county_tracts.dig(county_name)
  end
end
