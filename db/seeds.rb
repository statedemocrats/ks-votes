# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# county FIPS info from census.gov
# https://www2.census.gov/geo/docs/reference/codes/files/st20_ks_cou.txt

ks_counties = [ 
"KS,20,001,Allen County,H1",
"KS,20,003,Anderson County,H1",
"KS,20,005,Atchison County,H1",
"KS,20,007,Barber County,H1",
"KS,20,009,Barton County,H1",
"KS,20,011,Bourbon County,H1",
"KS,20,013,Brown County,H1",
"KS,20,015,Butler County,H1",
"KS,20,017,Chase County,H1",
"KS,20,019,Chautauqua County,H1",
"KS,20,021,Cherokee County,H1",
"KS,20,023,Cheyenne County,H1",
"KS,20,025,Clark County,H1",
"KS,20,027,Clay County,H1",
"KS,20,029,Cloud County,H1",
"KS,20,031,Coffey County,H1",
"KS,20,033,Comanche County,H1",
"KS,20,035,Cowley County,H1",
"KS,20,037,Crawford County,H1",
"KS,20,039,Decatur County,H1",
"KS,20,041,Dickinson County,H1",
"KS,20,043,Doniphan County,H1",
"KS,20,045,Douglas County,H1",
"KS,20,047,Edwards County,H1",
"KS,20,049,Elk County,H1",
"KS,20,051,Ellis County,H1",
"KS,20,053,Ellsworth County,H1",
"KS,20,055,Finney County,H1",
"KS,20,057,Ford County,H1",
"KS,20,059,Franklin County,H1",
"KS,20,061,Geary County,H1",
"KS,20,063,Gove County,H1",
"KS,20,065,Graham County,H1",
"KS,20,067,Grant County,H1",
"KS,20,069,Gray County,H1",
"KS,20,071,Greeley County,H1",
"KS,20,073,Greenwood County,H1",
"KS,20,075,Hamilton County,H1",
"KS,20,077,Harper County,H1",
"KS,20,079,Harvey County,H1",
"KS,20,081,Haskell County,H1",
"KS,20,083,Hodgeman County,H1",
"KS,20,085,Jackson County,H1",
"KS,20,087,Jefferson County,H1",
"KS,20,089,Jewell County,H1",
"KS,20,091,Johnson County,H1",
"KS,20,093,Kearny County,H1",
"KS,20,095,Kingman County,H1",
"KS,20,097,Kiowa County,H1",
"KS,20,099,Labette County,H1",
"KS,20,101,Lane County,H1",
"KS,20,103,Leavenworth County,H1",
"KS,20,105,Lincoln County,H1",
"KS,20,107,Linn County,H1",
"KS,20,109,Logan County,H1",
"KS,20,111,Lyon County,H1",
"KS,20,113,McPherson County,H1",
"KS,20,115,Marion County,H1",
"KS,20,117,Marshall County,H1",
"KS,20,119,Meade County,H1",
"KS,20,121,Miami County,H1",
"KS,20,123,Mitchell County,H1",
"KS,20,125,Montgomery County,H1",
"KS,20,127,Morris County,H1",
"KS,20,129,Morton County,H1",
"KS,20,131,Nemaha County,H1",
"KS,20,133,Neosho County,H1",
"KS,20,135,Ness County,H1",
"KS,20,137,Norton County,H1",
"KS,20,139,Osage County,H1",
"KS,20,141,Osborne County,H1",
"KS,20,143,Ottawa County,H1",
"KS,20,145,Pawnee County,H1",
"KS,20,147,Phillips County,H1",
"KS,20,149,Pottawatomie County,H1",
"KS,20,151,Pratt County,H1",
"KS,20,153,Rawlins County,H1",
"KS,20,155,Reno County,H1",
"KS,20,157,Republic County,H1",
"KS,20,159,Rice County,H1",
"KS,20,161,Riley County,H1",
"KS,20,163,Rooks County,H1",
"KS,20,165,Rush County,H1",
"KS,20,167,Russell County,H1",
"KS,20,169,Saline County,H1",
"KS,20,171,Scott County,H1",
"KS,20,173,Sedgwick County,H1",
"KS,20,175,Seward County,H1",
"KS,20,177,Shawnee County,H1",
"KS,20,179,Sheridan County,H1",
"KS,20,181,Sherman County,H1",
"KS,20,183,Smith County,H1",
"KS,20,185,Stafford County,H1",
"KS,20,187,Stanton County,H1",
"KS,20,189,Stevens County,H1",
"KS,20,191,Sumner County,H1",
"KS,20,193,Thomas County,H1",
"KS,20,195,Trego County,H1",
"KS,20,197,Wabaunsee County,H1",
"KS,20,199,Wallace County,H1",
"KS,20,201,Washington County,H1",
"KS,20,203,Wichita County,H1",
"KS,20,205,Wilson County,H1",
"KS,20,207,Woodson County,H1",
"KS,20,209,Wyandotte County,H6",
]

puts "Loading Counties"
cty_map = {}
ks_counties.each do |line|
  state, state_fips, cty_fips, name, fips_class = line.split(',')
  cty = County.create(name: name.gsub(' County', ''), fips: cty_fips)
  cty_map[cty_fips] = cty
end

puts "Loading 2012 Census tracts"
# run in a single transaction for speed.
seen_names = {}
CensusTract.transaction do
  precinct_names = File.join(Rails.root, 'db/kansas-2012-precinct-names.csv')
  CSV.foreach(precinct_names, headers: true) do |row|
    name = row['name']
    vtd = row['vtd']
    matches = vtd.match(/^20(\d\d\d)(\w+)$/)
    #puts "#{name} #{code} #{matches.to_a.inspect}"
    cty_fips = matches[1]
    precinct_code = matches[2]
    cty_id = cty_map[cty_fips].id

    # dupe check
    seen_names[cty_id] ||= {}
    if seen_names[cty_id][name]
      STDERR.puts "WARNING dupe precinct '#{name}' with vtd #{seen_names[cty_id][name]} (#{precinct_code})"
    end
    seen_names[cty_id][name] = precinct_code

    # not .create() because we want to skip validations for speed.
    c = CensusTract.new(county_id: cty_id, vtd_code: precinct_code, name: name, year: '2012', reason: :census)
    c.save!(validate: false)
    p = Precinct.new(county_id: cty_id, name: name, census_tract_id: c.id)
    p.save!(validate: false)
  end
end

puts "Loading 2020 VTDs"
CensusTract.transaction do
  vtds = File.join(Rails.root, 'db/kansas-2020-vtds-shas.csv')
  CSV.foreach(vtds, headers: true) do |row|
    name = row['name']
    vtd = row['vtdst']
    cty_fips = row['countyfp']
    sha = row['geosha']
    cty = cty_map[cty_fips]
    cty_id = cty.id

    # dupe check
    seen_names[cty_id] ||= {}
    if seen_names[cty_id][name]
      if seen_names[cty_id][name] != vtd
        STDERR.puts "WARNING: VTD changed for #{cty.name} #{cty_fips} :: #{name}"
      end

      next # TODO we probably do not need/want to save lots of dupes differing only by year
    else
      STDERR.puts "New VTD: #{cty.name} #{cty_fips} :: #{name}"
    end

    c = CensusTract.new(county_id: cty_id, vtd_code: vtd, name: name, year: '2020', reason: :census)
    c.save!(validate: false)
    p = Precinct.new(county_id: cty_id, name: name, census_tract_id: c.id)
    p.save!(validate: false)
  end
end

