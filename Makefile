# common tasks too simple for Rakefile

clean:
	rake db:reset precincts:aliases

2012:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2012

2016:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2016

joco2016:
	rake openelections:load_file FILE=../openelections-data-ks/2016/20161108__ks__general__johnson__precinct.csv

wyandotte2016:
	rake openelections:load_file FILE=../openelections-data-ks/2016/20161108__ks__general__wyandotte__precinct.csv

.PHONY: 2012
