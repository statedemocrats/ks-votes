# common tasks too simple for Rakefile

clean:
	rake db:reset precincts:aliases

2012:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2012

2016:
	rake openelections:load_files OE_DIR=../openelections-data-ks/ YEAR=2016

.PHONY: 2012
