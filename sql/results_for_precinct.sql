select candidate_id,office_id,election_id,votes,e.name,o.name
from results as r, elections as e, offices as o
where r.precinct_id = {0}
and e.id=r.election_id and o.id=r.office_id
