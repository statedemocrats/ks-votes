# common tasks too simple for Rakefile

clean:
	rake db:reset precincts:aliases

deploy:
	rake map:setup

2012:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2012

2016:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2016

joco2016:
	rake openelections:load_file FILE=../openelections-data-ks/2016/20161108__ks__general__johnson__precinct.csv

wyandotte2016:
	rake openelections:load_file FILE=../openelections-data-ks/2016/20161108__ks__general__wyandotte__precinct.csv

geosha-kansas:
	rake map:geosha IN_FILE=public/kansas-state-voting-precincts-2012-min.geojson OUT_FILE=kansas-state-voting-precincts-2012-sha-min.geojson

.PHONY: 2012
