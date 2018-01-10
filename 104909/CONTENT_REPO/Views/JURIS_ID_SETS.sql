CREATE OR REPLACE FORCE VIEW content_repo.juris_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid) AS
select j.id, j.nkid, j.rid, j.next_rid, jr.id entity_rid, jr.next_Rid entity_next_rid
from jurisdictions j
join jurisdiction_revisions jr on (
    jr.nkid = j.nkid
    and rev_join(j.rid,jr.id,j.next_rid) = 1
    )
 
 
 ;