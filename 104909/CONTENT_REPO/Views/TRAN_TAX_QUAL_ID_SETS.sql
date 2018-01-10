CREATE OR REPLACE FORCE VIEW content_repo.tran_tax_qual_id_sets ("ID",nkid,rid,next_rid,entity_nkid,entity_rid,entity_next_rid) AS
select ttq.id, ttq.nkid, ttq.rid, ttq.next_rid, jtr.nkid entity_nkid, jtr.id entity_rid, jtr.next_Rid entity_next_rid
from tran_tax_qualifiers ttq
join juris_tax_applicabilities jti on (jti.id = ttq.juris_tax_applicability_id)
join juris_tax_app_revisions jtr on (
    jtr.nkid = jti.nkid
    and rev_join(ttq.rid,jtr.id,ttq.next_rid) = 1
    )
--)
order by nkid, rid, entity_rid;