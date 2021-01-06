# common tasks too simple for Rakefile

start-services:
	docker-compose up -d

stop-services:
	docker-compose down

c:
	bundle exec rails console

db:
	bundle exec rails dbconsole

setup:
	bundle install
	rake db:setup map:setup
	createdb voter_files -h localhost -U postgres

clean:
	rm -f log/development.log
	rake db:reset precincts:aliases

install:
	rake map:setup

report:
	rake precincts:report:by_year map:census_tracts map:csv

publish-results:
	scp public/all-precincts-by-year.json statedemocrats.us:/data/statedemocrats.us/kansas/map/
	scp public/all-tracts-by-year.json statedemocrats.us:/data/statedemocrats.us/kansas/map/

publish-csv:
	scp public/election-results-combined.csv statedemocrats.us:/data/statedemocrats.us/kansas/map/

publish-app:
	ssh statedemocrats.us 'cd /data/statedemocrats.us/kansas/map/ && git pull'

publish: publish-results publish-csv publish-app

deploy: publish

check:
	rake precincts:check:duplicate_map_ids precincts:check:duplicate_names precincts:check:missing_census_tract

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

2018:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2018

2020:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2020

years:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2012,2014,2016,2017,2018,2020

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
	psql -U postgres -h localhost -d voter_files < sql/voter_files.sql

index:
	rake environment elasticsearch:ha:import NPROCS=2 CLASS=Voter FORCE=1

douglas-stats:
	rake precincts:douglas
	rake voters:vtds voters:county_stats COUNTY=Douglas
	cp public/douglas-county-voters-stats.json ../ks-douglas-county/
	scp public/douglas-county-voters-stats.json pekmac:~/projects/ks-douglas-county/

fresh: clean check years report publish-results

.PHONY: 2012 2014 2016 2020 orphans db
