CREATE OR REPLACE FORCE VIEW content_repo.vcontact_administrators ("ID",nkid,rid,admin_id,admin_nkid,admin_rid,source_id,entered_by,entered_date) AS
SELECT ac.id, ac.nkid, ac.rid, a.id admin_id, a.nkid admin_nkid, a.rid admin_rid, ac.source_id, ac.entered_by, ac.entered_date
from administrators a
join administrator_contacts ac on (a.id = ac.administrator_id)
 
 
 ;