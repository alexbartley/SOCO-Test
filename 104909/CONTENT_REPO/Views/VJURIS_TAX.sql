CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax ("ID",nkid,rid,next_rid,juris_tax_entity_rid,juris_tax_next_rid,reference_code,description,tax_description_id,tax_descripiton,revenue_purpose_id,revenue_purpose,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
select  jti.id , jti.nkid, jti.rid rid, jti.next_rid, r.id juris_entity_rid, r.next_rid, jti.reference_code, jti.description,
  td.id, td.name,
  rp.id, rp.name,
  jti.start_date, jti.end_Date, jti.status, jti.status_modified_date, jti.entered_by, jti.entered_date
from jurisdiction_tax_revisions r
join juris_tax_impositions jti on (
    r.nkid = jti.nkid
    AND r.id >= jti.rid
    and r.id < NVL(jti.next_rid,999999999)
)
join tax_descriptions td on (td.id = jti.tax_description_id)
left outer join revenue_purposes rp on (rp.id = jti.revenue_purpose_id)--these don't currently exist
 
 
 ;