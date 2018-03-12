# common tasks too simple for Rakefile

setup:
	bundle install
	rake db:setup map:setup

clean:
	rm -f log/development.log
	rake db:reset precincts:aliases

deploy:
	rake map:setup

report:
	rake precincts:report:by_year map:census_tracts

publish-results:
	scp public/all-precincts-by-year.json statedemocrats.us:/data/statedemocrats.us/kansas/map/
	scp public/all-tracts-by-year.json statedemocrats.us:/data/statedemocrats.us/kansas/map/

publish-app:
	ssh statedemocrats.us 'cd /data/statedemocrats.us/kansas/map/ && git pull'

publish: publish-results publish-app

check:
	rake precincts:check:duplicate_map_ids precincts:check:duplicate_names

orphans:
	@psql -q -A -F '","' -d ksvotes < sql/orphan-precincts.sql | grep -v ' rows' | sed 's/\(.*\)/"\1"/g' | sed 's/""//g'

2012:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2012

2014:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2014

2016:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2016

2017:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2017

years:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2012,2014,2016,2017

joco:
	rake openelections:load_file FILE=../openelections-data-ks/2016/20161108__ks__general__johnson__precinct.csv
	rake openelections:load_file FILE=../openelections-data-ks/2014/20141104__ks__general__johnson__precinct.csv
	rake openelections:load_file FILE=../openelections-data-ks/2012/20121106__ks__general__johnson__precinct.csv

wyandotte2016:
	rake openelections:load_file FILE=../openelections-data-ks/2016/20161108__ks__general__wyandotte__precinct.csv

sedg2012:
	rake openelections:load_file FILE=../openelections-data-ks/2012/20121106__ks__general__sedgwick__precinct.csv

geosha-kansas:
	rake map:geosha IN_FILE=public/kansas-state-voting-precincts-2012-min.geojson OUT_FILE=public/kansas-state-voting-precincts-2012-sha-min.geojson

clean-voters:
	psql -d voter_files < sql/voter_files.sql

index:
	rake environment elasticsearch:ha:import NPROCS=2 CLASS=Voter FORCE=1

.PHONY: 2012 2014 2016 orphans
