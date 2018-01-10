CREATE OR REPLACE FORCE VIEW content_repo.vadministrator_attributes ("ID",nkid,rid,next_rid,admin_id,admin_nkid,admin_rid,attribute_value,attribute_name,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
select ada.id, ada.nkid, ada.rid, ada.next_rid, ad.id, r.nkid admin_nkid, r.id admin_entity_rid,
ada.value, aa.name, ada.start_date, ada.end_date, ada.status, ada.status_modified_date, ada.entered_by, ada.entered_date
from administrator_revisions r
join administrators ad ON (r.nkid = ad.nkid)
join administrator_attributes ada ON (
    ada.administrator_id = ad.id
    AND r.id >= ada.rid
    and r.id < NVL(ada.next_rid,99999999)
)
join additional_attributes aa on (aa.id = ada.attribute_id)
 
 
 ;