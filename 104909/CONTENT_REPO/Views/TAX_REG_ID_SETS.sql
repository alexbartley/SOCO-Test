CREATE OR REPLACE FORCE VIEW content_repo.tax_reg_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,entity_nkid,admin_id) AS
select tr.id, tr.nkid, tr.rid, tr.next_rid, ar.id entity_rid, ar.next_Rid entity_next_rid, a.nkid, a.id
from tax_registrations tr
join administrators a on (a.id = tr.administrator_id)
join administrator_revisions ar on (
    ar.nkid = a.nkid
    and rev_join(tr.rid,ar.id,tr.next_rid) = 1
    )
 
 
 ;