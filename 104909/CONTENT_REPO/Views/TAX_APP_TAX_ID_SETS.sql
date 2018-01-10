CREATE OR REPLACE FORCE VIEW content_repo.tax_app_tax_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid) AS
select tat.id, tat.nkid, tat.rid, tat.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid
from tax_applicability_taxes tat
join juris_tax_applicabilities jta on (jta.id = tat.juris_tax_applicability_id)
join juris_tax_app_revisions jtr on (
    jtr.nkid = jta.nkid
    and rev_join(tat.rid,jtr.id,tat.next_rid) = 1
    )
--)
order by nkid, rid, entity_rid
 
 
 ;