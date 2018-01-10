CREATE OR REPLACE FORCE VIEW content_repo.vjurisdiction_attribute_lookup ("ID",nkid,rid,next_rid,juris_id,juris_nkid,juris_rid,juris_next_rid,attribute_category,attribute_category_id,"VALUE",value_id,attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
(Select
  vja.id
, vja.nkid
, vja.rid
, vja.next_rid
, vja.juris_id
, vja.juris_nkid
, vja.juris_rid
, vja.juris_next_rid
, vja.attribute_category
, vja.attribute_category_id
, CASE WHEN vja.attribute_id = fnjurisattribadmin(1)
       then fnlookupadminbynkid(vja.value)
  else
       vja.value
  END value,
  CASE WHEN vja.attribute_id = fnjurisattribadmin(1)
       then vja.value
  else
       null
END value_id
-- old: , vja.value
, vja.attribute_name
, vja.attribute_id
, vja.start_date
, vja.end_date
, vja.status
, vja.status_modified_date
, vja.entered_by
, vja.entered_date
from vjurisdiction_attributes vja
)
 
 ;