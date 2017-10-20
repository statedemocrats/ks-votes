class PrecinctFinder
  include Term::ANSIColor

  FUZZY_TOOLS_THRESHOLD = 0.7
  FUZZY_MATCH_THRESHOLD = 0.5

  @@county_tracts = County.all.map { |cty| [cty.name, cty.census_tracts.pluck(:name, :id).to_h ] }.to_h

  def self.county_tracts
    @@county_tracts
  end

  def debug?
    ENV['DEBUG'] == '1'
  end

  def county_tracts
    @@county_tracts
  end

  def normalize(name)
    name.strip
      .gsub('#', ' ')
      .gsub(/\ \ +/, ' ')
      .gsub(' / ', '/')
      .gsub(/-([A-G])\b/, ' Part \1')
      .gsub(/\btwp\b/i, 'Township')
      .gsub(/\bpct\b/i, 'Precinct')
      .gsub(/\bpre\b/i, 'Precinct')
      .gsub(/\bwd\b/i, 'Ward')
      .gsub(/\bW\ (\d+)\ P (\d+)\b/, 'W\1P\2')
      .gsub(/\bW(\d+)P(\d+)\b/, 'Ward \1 Precinct \2')
      .gsub(/\bW(\d+)\b/, 'Ward \1')
      .gsub(/\bN\.\b/, 'North')
      .gsub(/\bN\b/, 'North')
      .gsub(/\bS\.\b/, 'South')
      .gsub(/\bS\b/, 'South')
      .gsub(/\bE\.\b/, 'East')
      .gsub(/\bE\b/, 'East')
      .gsub(/\bW\.\b/, 'West')
      .gsub(/\bW\b/, 'West')
      .gsub(/\bFT\.\b/i, 'Fort')
      .gsub(/\bFT\b/i, 'Fort')
      .gsub(/\bCk\.\b/, 'Creek')
      .gsub(/\bCk\b/, 'Creek')
      .gsub(/\bCtr\b/, 'Center')
      .gsub(/([1-9])(st|nd|rd|th) (Ward|Precinct)/i, '\3 \1')
  end

  def likely_name(county, precinct_name)
    precinct_name = normalize(precinct_name)

    # leading digits are never part of census tract
    if precinct_name.match(/^\d\d\d+[\-\ ]+/)
      precinct_name.sub!(/^\d\d\d+[\-\ ]+/, '')
    end

    precinct_name = precinct_name.titlecase if precinct_name.match(/^[A-Z\ ]+$/)

    # try with/without Township suffix
    if !county_tracts.dig(county.name, precinct_name)
      if county_tracts.dig(county.name, "#{precinct_name} Township")
        precinct_name += ' Township'
      elsif precinct_name.match(/ Township$/)
        maybe_precinct_name = precinct_name.sub(/ Township$/, '')
        precinct_name = maybe_precinct_name if county_tracts.dig(county.name, maybe_precinct_name)
      end
    end

    if precinct_name.match(/twp [\-\d]+$/)
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

    # if we still don't have an exact match, try a fuzzy match
    if !county_tracts.dig(county.name, precinct_name)
      before = precinct_name
      precinct_name = fuzzy_match(county.name, precinct_name)
      if before != precinct_name and debug?
        puts "[#{county.name}] Fuzzy match #{cyan(before)} -> #{blue(precinct_name)}"
      end
    end

    precinct_name
  end

  def matcher(haystack)
    FuzzyMatch.new(haystack,
      threshold: FUZZY_MATCH_THRESHOLD,
      find_best: true,
      find_all_with_score: true,
      stop_words: ['Precinct', 'Ward', 'Township'],
    )
  end

  def do_fuzzy_match(county_name, precinct_name)
    county_precincts = county_tracts.dig(county_name).keys
    simple_name = precinct_name
      .gsub(/[\.\,\-\/]/, ' ') # help word tokenization
      .gsub(/\ \ +/, ' ')
      .gsub(/\b0(\d+)/, '\1')  # strip leading zeroes
    m = matcher(county_precincts).find(simple_name)
    { simple: simple_name, precinct: precinct_name, matches: m }
  end

  def fuzzy_match(county_name, precinct_name)
    m = do_fuzzy_match(county_name, precinct_name)
    return precinct_name unless m[:matches].any?
    first_match = m[:matches][0][0]
    pp m if debug?
    if m[:matches].length > 1

      # if top 2 matches have similar scores, too ambiguous.
      return precinct_name if m[:matches][0][1] == m[:matches][1][1] && m[:matches][0][2] == m[:matches][1][2]

      # if the first match has obvious substring, allow it. otherwise too ambiguous.
      substr_match = 0
      is_first = false
      m[:matches].each do |potential|
        m1 = potential[0]
        if m1.match(precinct_name) || precinct_name.match(m1) || m1.match(m[:simple]) || m[:simple].match(m1)
          substr_match += 1
          is_first = m1 == first_match
        end
      end
      if substr_match == 1 && is_first
        return first_match
      else
        # use fuzzy_tools against our pool
        pool = m[:matches].map { |m1| m1[0] }
        ftools = pool.fuzzy_find_all_with_scores(precinct_name)
        pp( { fuzzy_tools: ftools } ) if debug?
        ftools.each do |m1|
          n, score = m1
          if score.round(1) >= FUZZY_TOOLS_THRESHOLD # TODO right threshold?
            return n
          end
        end
        return precinct_name
      end
    else
      return first_match
    end
  end

  def precinct_for_county!(county, precinct_name, election_file)
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
        .where('lower(precinct_aliases.name) IN (?)', [precinct_name.downcase, orig_precinct_name.downcase]).first
      if pa
        puts "[#{county.name}] Found precinct #{green(pa.precinct.name)} via alias #{blue(precinct_name)} | #{red(orig_precinct_name)}" if debug?
        precinct_name = pa.precinct.name
        census_tract_id = pa.precinct.census_tract_id # might be null, that's ok.
        precinct = pa.precinct

      # no alias? look for common permutations
      else
        before = precinct_name
        precinct_name = likely_name(county, precinct_name)
        if debug?
          puts "[#{county.name}] Likely #{cyan(precinct_name)} from #{red(before)} [#{magenta(orig_precinct_name)}]"
        end
      end
    end

    # if we still don't have a census_tract, try again with the altered name.
    census_tract_id ||= county_tracts.dig(county.name, precinct_name) || nil

    # one last try to find precinct based on normalized name (searches aliases too)
    precinct ||= Precinct.find_by_any_name(precinct_name, county.id).first

    # make sure Precinct exists, no matter what.
    # NOTE we do NOT pass in census_precinct_id to create a new Precinct since we trust it is
    # *NOT* the primary precinct for the census tract (in which case we would have found it above).
    if !precinct
      puts "[#{county.name}] Creating precinct #{green(precinct_name)}"
      precinct = Precinct.create(county_id: county.id, name: precinct_name, election_file_id: election_file.id)
    end

    # finally, create Precinct relations if we could not identify 1:1 with CensusTract
    if !census_tract_id && !precinct.census_tract_id
      if orig_precinct_name != precinct_name && !precinct.has_alias?(orig_precinct_name)
        puts "[#{county.name}] Alias new precinct #{blue(orig_precinct_name)} -> #{blue(precinct_name)}"
        PrecinctAlias.create(name: orig_precinct_name, precinct_id: precinct.id, reason: :orphan)
      end
    end
    precinct
  end
end
