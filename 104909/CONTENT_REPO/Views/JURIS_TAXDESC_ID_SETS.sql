CREATE OR REPLACE FORCE VIEW content_repo.juris_taxdesc_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,entity_nkid,juris_id,tax_description_id) AS
select jtd.id, jtd.nkid, jtd.rid, jtd.next_rid, jr.id entity_rid, jr.next_Rid entity_next_rid, j.nkid, j.id, jtd.tax_description_id
from juris_tax_descriptions jtd
join jurisdictions j on (j.id = jtd.jurisdiction_id)
join jurisdiction_revisions jr on (
    jr.nkid = j.nkid
    and rev_join(jtd.rid,jr.id,jtd.next_rid) = 1
    )
 
 
 ;