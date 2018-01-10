CREATE OR REPLACE FORCE VIEW content_repo.admin_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid) AS
select a.id, a.nkid,a.rid, a.next_rid, ar.id entity_rid, ar.next_Rid entity_next_rid
from administrators a
join administrator_revisions ar on (
    ar.nkid = a.nkid
    and rev_join(a.rid,ar.id,a.next_rid) = 1
    )
 
 
 ;