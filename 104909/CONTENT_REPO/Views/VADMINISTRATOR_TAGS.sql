CREATE OR REPLACE FORCE VIEW content_repo.vadministrator_tags (admin_nkid,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT DISTINCT ad.nkid, t.id, t.name, t.tag_type_id, ptt.entered_by, ptt.entered_date, ptt.status
FROM administrator_tags ptt
join tags t on (t.id = ptt.tag_id)
JOIN administrators ad on (ad.nkid = ptt.ref_nkid)
--WHERE ptt.table_name = 'ADMINISTRATORS'
 
 
 ;