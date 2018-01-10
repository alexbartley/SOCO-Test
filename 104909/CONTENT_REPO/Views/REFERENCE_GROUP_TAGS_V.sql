CREATE OR REPLACE FORCE VIEW content_repo.reference_group_tags_v ("ID",reference_group_id,reference_group_nkid,reference_group_rid,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT DISTINCT ptt.id, ad.id, ad.nkid, ad.rid, t.id, t.name, t.tag_type_id, ptt.entered_by, ptt.entered_date, ptt.status
FROM ref_group_tags ptt
join tags t on (t.id = ptt.tag_id)
JOIN reference_groups ad on (ad.nkid = ptt.ref_nkid)
 
 
 ;