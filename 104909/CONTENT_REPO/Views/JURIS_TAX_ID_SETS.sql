CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,juris_id,juris_nkid,juris_rid) AS
select jti.id, jti.nkid, jti.rid, jti.next_rid, jtr.id entity_rid, jtr.next_Rid entity_next_rid, j.id juris_id, j.nkid juris_nkid, j.rid juris_rid
from juris_tax_impositions jti
join jurisdiction_tax_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(jti.rid,jtr.id,jti.next_rid) = 1
    )
join jurisdictions j on (j.id = jti.jurisdiction_id)
 
 
 ;