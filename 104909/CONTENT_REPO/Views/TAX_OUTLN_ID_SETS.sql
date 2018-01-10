CREATE OR REPLACE FORCE VIEW content_repo.tax_outln_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid,is_current,juris_tax_id) AS
select tou.id, tou.nkid, tou.rid, tou.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid, is_current(tou.rid,jtr.next_rid,tou.next_rid) is_current, jti.id
from tax_outlines tou
join juris_tax_impositions jti on (jti.id = tou.juris_tax_imposition_id)
join jurisdiction_tax_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(tou.rid,jtr.id,tou.next_rid) = 1
    )
--)
 
 
 ;