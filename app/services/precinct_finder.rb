class PrecinctFinder
  @@county_tracts = County.all.map { |cty| [cty.name, cty.census_tracts.pluck(:name, :id).to_h ] }.to_h

  def self.county_tracts
    @@county_tracts
  end

  def county_tracts
    @@county_tracts
  end

  def normalize(name)
    name.strip
      .gsub(/\ \ +/, ' ')
      .gsub(' / ', '/')
      .gsub(/\btwp\b/i, 'Township')
  end

  def likely_name(county, precinct_name)
    precinct_name = normalize(precinct_name)
    if county_tracts.dig(county.name, "#{precinct_name} Township")
      precinct_name += ' Township'
    elsif county_tracts.dig(county.name, precinct_name.gsub(/\btwp\b/i, 'Township'))
      precinct_name.gsub!(/\btwp\b/i, 'Township')
    elsif precinct_name.match(/twp$/i)
      maybe_precinct_name = precinct_name.sub(/twp$/i, 'Township')
      precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
    elsif precinct_name.match(/twp [\-\d]+$/)
      maybe_precinct_name = precinct_name.sub(/twp ([\d\-]+)$/i, 'Township Precinct \1')
      precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
    elsif precinct_name.match(/\w, \w/)
      parts = precinct_name.split(', ')
      maybe_precinct_name = parts[1] + ' ' + parts[0]
      precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
    elsif precinct_name.match(/^[A-Z\d\ ]+$/)
      maybe_precinct_name = precinct_name.titlecase
      precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
    elsif precinct_name.match(/\ 0(\d)/)
      # strip leading zero
      maybe_precinct_name = precinct_name.gsub(/\ 0(\d)/, ' \1')
      precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)

    # MUST be last
    elsif precinct_name.match(/Precinct/)
      maybe_precinct_name = precinct_name.sub(/^.+?Precinct/, 'Precinct')
      precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
    end
    precinct_name
  end

  def precinct_for_county(county, precinct_name, election_file)
    orig_precinct_name = precinct_name

    # common clean up first since we'll create from this string
    precinct_name = normalize(precinct_name)

    #puts "Orig precinct '#{orig_precinct_name}' cleaned '#{precinct_name}'"

    # check cache of tract names
    census_tract_id = county_tracts.dig(county.name, precinct_name)

    # we might find it along the way
    precinct = nil

    # if we can't find an exact name match on precinct and census_tract,
    # we'll start to permutate the name to try and find a match.
    if !census_tract_id
      # first, look in the known aliases
      pa = PrecinctAlias.includes(:precinct) \
        .where(precincts: { county_id: county.id }) \
        .find_by(name: [precinct_name, orig_precinct_name])
      if pa
        precinct_name = pa.precinct.name
        census_tract_id = pa.precinct.census_tract_id # might be null, that's ok.
        precinct = pa.precinct

      # no alias? look for common permutations
      else
        precinct_name = likely_name(county, precinct_name)
      end
    end

    # if we still don't have a census_tract, try again with the altered name.
    census_tract_id ||= county_tracts.dig(county.name, precinct_name) || nil

    # make sure Precinct exists, no matter what.
    # NOTE we do NOT pass in census_precinct_id to create a new Precinct since we trust it is
    # *NOT* the primary precinct for the census tract (in which case we would have found it above).
    precinct ||= Precinct.where(county_id: county.id).where('lower(name) = ?', precinct_name.downcase).first
    precinct ||= Precinct.find_or_create_by(county_id: county.id, name: precinct_name) do |p|
      p.election_file_id = election_file.id
    end

    # finally, create Precinct relations if we could not identify 1:1 with CensusTract
    if !census_tract_id && !precinct.census_tract_id
      if orig_precinct_name != precinct_name && !precinct.has_alias?(orig_precinct_name)
        puts "Aliasing #{orig_precinct_name} -> #{precinct_name}"
        PrecinctAlias.create(name: orig_precinct_name, precinct_id: precinct.id)
      end
    else
      # census_tract.name == precinct_name
      # TODO do we need the secondary CensusPrecinct?
      #CensusPrecinct.find_or_create_by(precinct_id: precinct.id, census_tract_id: census_tract_id)
    end
    precinct
  end
end
