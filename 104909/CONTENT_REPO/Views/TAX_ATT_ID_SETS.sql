CREATE OR REPLACE FORCE VIEW content_repo.tax_att_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid) AS
select ta.id, ta.nkid, ta.rid, ta.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid
from tax_attributes ta
join juris_tax_impositions jti on (jti.id = ta.juris_tax_imposition_id)
join jurisdiction_tax_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(ta.rid,jtr.id,ta.next_rid) = 1
    )
 
 
 ;