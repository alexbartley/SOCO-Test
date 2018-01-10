CREATE OR REPLACE FORCE VIEW content_repo.juris_att_id_sets ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,entity_nkid,juris_id,attribute_id) AS
select ja.id, ja.nkid, ja.rid, ja.next_rid, jr.id entity_rid, jr.next_Rid entity_next_rid, j.nkid, j.id, ja.attribute_id
from jurisdiction_Attributes ja
join jurisdictions j on (j.id = ja.jurisdiction_id)
join jurisdiction_revisions jr on (
    jr.nkid = j.nkid
    and rev_join(ja.rid,jr.id,ja.next_rid) = 1
    )
 
 
 ;