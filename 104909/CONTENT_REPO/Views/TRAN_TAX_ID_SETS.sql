CREATE OR REPLACE FORCE VIEW content_repo.tran_tax_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid) AS
select tt.id, tt.nkid, tt.rid, tt.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid
from transaction_taxabilities tt
join juris_tax_applicabilities jti on (jti.id = tt.juris_tax_applicability_id)
join juris_tax_app_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(tt.rid,jtr.id,tt.next_rid) = 1
    )
--)
order by nkid, rid, entity_rid
 
 
 ;