select p.name as precinct,p.county_id,c.name as county,'' as vtd_2012, '' as census_tracts
from precincts as p, counties as c
where county_id=c.id and p.id > 4244
and p.id not in (select precinct_id from census_precincts)
and p.census_tract_id is null
order by c.name, p.name
