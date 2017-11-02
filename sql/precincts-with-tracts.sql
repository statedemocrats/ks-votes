select p.id,p.name,p.census_tract_id,c.vtd_code
from precincts as p left join census_tracts as c on c.id=p.census_tract_id
where p.county_id in (select id from counties where name = '{0}')
order by p.name;
