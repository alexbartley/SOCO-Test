CREATE OR REPLACE FORCE VIEW content_repo.tax_def_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid,is_current,tax_outline_nkid,tax_outline_id) AS
select td.id, td.nkid, td.rid, td.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid, is_current(td.rid,jtr.next_rid,td.next_rid) is_current, tou.nkid, tou.id
from tax_definitions td
join tax_outlines tou on (tou.id = td.tax_outline_id)
join juris_tax_impositions jti on (jti.id = tou.juris_tax_imposition_id)
join jurisdiction_tax_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(td.rid,jtr.id,td.next_rid) = 1
    )
 
 
 ;