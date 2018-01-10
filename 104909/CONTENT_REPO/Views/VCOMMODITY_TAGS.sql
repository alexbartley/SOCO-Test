CREATE OR REPLACE FORCE VIEW content_repo.vcommodity_tags (commodity_nkid,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT DISTINCT ad.nkid, t.id, t.name, t.tag_type_id, ptt.entered_by, ptt.entered_date, ptt.status
FROM commodity_tags ptt
join tags t on (t.id = ptt.tag_id)
JOIN commodities ad on (ad.nkid = ptt.ref_nkid)
 
 
 ;