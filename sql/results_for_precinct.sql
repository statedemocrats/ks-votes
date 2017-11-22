select votes,c.name,e.name,o.name,checksum
from results as r, elections as e, offices as o, candidates as c
where r.precinct_id = {0}
and e.id=r.election_id and o.id=r.office_id and c.id=r.candidate_id
