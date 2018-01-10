CREATE OR REPLACE FORCE VIEW content_repo.tax_output_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid) AS
select tou.id, tou.nkid, tou.rid, tou.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid
from taxability_outputs tou
join juris_tax_applicabilities jti on (jti.id = tou.juris_tax_applicability_id)
join juris_tax_app_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(tou.rid,jtr.id,tou.next_rid) = 1
    )
--)
order by nkid, rid, entity_rid
 
 
 ;