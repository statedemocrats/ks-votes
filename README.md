# KS votes

This is a Rails 5 application for collecting and analyzing Kansas elections. We collect

* election results
* SOS voter file data
* census data

into a normalized database for further analysis.

## Setup

```bash
 % git clone git@github.com:statedemocrats/ks-votes.git
 % cd ks-votes
 % make setup
```

## Loading data

### OpenElections

To load election results from the OpenElections project, you must clone the relevant Github repo:

```bash
 % cd ..
 % git clone https://github.com/openelections/openelections-data-ks.git
 % cd -
```

and then run the relevant rake task to load the results:

```bash
 % rake openelections:load_files OE_DIR=path/to/openelections-data-ks YEAR=2016,2014,2012
 # or, if your OE_DIR is in the default path at ../openelections-data-ks, simply:
 % make 2016 2014 2012
```


## Map

### Setup the map artifacts

```bash
 % rake map:setup
```

### Per county shapefiles

Lacking up-to-date state-wide files, you can convert per-county shapefiles to GeoJSON like:

```bash
 % shp2geojson VOTINGPRECINCT_PL.shp EPSG:3419
```
