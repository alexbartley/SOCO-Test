CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_app_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,juris_id,juris_nkid,juris_rid) AS
select jti.id, jti.nkid, jti.rid, jti.next_rid, jtr.id entity_rid, jtr.next_Rid entity_next_rid, j.id juris_id, j.nkid juris_nkid, j.rid juris_rid
from juris_tax_applicabilities jti
join juris_tax_app_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(jti.rid,jtr.id,jti.next_rid) = 1
    )
join jurisdictions j on (j.id = jti.jurisdiction_id)
--)
order by nkid, rid, entity_rid
 
 
 ;