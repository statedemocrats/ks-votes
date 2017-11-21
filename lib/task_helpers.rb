module TaskHelpers
  def read_csv_gz(filename, &block)
    Zlib::GzipReader.open(filename) do |gzip|
      csv = CSV.new(gzip, headers: true)
      csv.each do |row|
        yield(row)
      end
    end
  end

  def curated_alias(precinct_id, name)
    PrecinctAlias.find_or_create_by(precinct_id: precinct_id, name: name) do |pa|
      pa.reason = :curated
    end
  end

  def curated_precinct_with_aliases(precinct_name, county, census_tract_id=nil)
    p = Precinct.find_or_create_by(name: precinct_name, county_id: county.id) do |pr|
      pr.census_tract_id = census_tract_id
    end
    aliases = [
      precinct_name.gsub(/(\d+)/) { Regexp.last_match[1].to_i },
      precinct_name.gsub(/(\d+)/) { sprintf('%02d', Regexp.last_match[1].to_i) }
    ]
    aliases.uniq.each do |n|
      next if n == precinct_name
      curated_alias(p.id, n)
      puts "[#{county.name}] Alias #{blue(n)} to new precinct #{precinct_name}"
    end
    p
  end

  def county_by_fips(county_fips)
    @_cbyfips ||= {}
    @_cbyfips[county_fips] ||= County.find_by!(fips: county_fips)
  end

  def county_tracts
    @_tracts ||= precinct_finder.county_tracts
  end

  def precinct_for_tract(tract)
    tract.precinct ||
      Precinct.find_by(name: tract.name, county_id: tract.county_id) ||
      tract.precincts.first ||
      Precinct.create(name: tract.name, county_id: tract.county_id)
  end

  def precinct_finder
    @_finder ||= PrecinctFinder.new
  end

  def find_county(name)
    @_counties ||= {}
    @_counties[name.downcase] ||= County.where('lower(name) = ?', name.downcase).first
  end

  def find_county_by_id(county_id)
    @_counties_by_id ||= {}
    @_counties_by_id[county_id] ||= County.find(county_id)
  end

  def find_tract_by_vtd(vtd_code, county)
    @_tracts_by_vtd ||= {}
    k = "#{county.name}|#{vtd_code}"
    @_tracts_by_vtd[k] ||= CensusTract.find_by(vtd_code: vtd_code, county_id: county.id)
  end

  def find_tract_by_id(id)
    @_tracts_by_id ||= {}
    @_tracts_by_id[id] ||= CensusTract.find(id)
  end

  def debug?
    ENV['DEBUG'] == '1'
  end

  def clean?
    ENV['CLEAN'] == '1'
  end

  def test_precinct_finder?
    ENV['TEST_PRECINCTS'] == '1'
  end

  def find_office(office_name, district_name, election_file_id)
    @_offices ||= {}
    norm_office = office_name.strip.downcase
    norm_district = district_name.strip.downcase.sub(/^h0?/, '')
    norm_office = Office::NORMS[norm_office] || office_name
    k = "#{norm_office},#{norm_district}"
    @_offices[k] ||= Office.find_or_create_by(name: norm_office, district: norm_district) do |o|
      o.election_file_id = election_file_id
    end
  end

  def find_party(party_name, election_file_id)
    @_parties ||= {}
    normed_name = Party::NORMS[party_name.strip.downcase] || party_name.to_sym
    @_parties[normed_name] ||= Party.find_or_create_by(name: normed_name) do |p|
      p.election_file_id = election_file_id
    end
  end
end
