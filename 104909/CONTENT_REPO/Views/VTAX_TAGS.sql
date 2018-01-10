CREATE OR REPLACE FORCE VIEW content_repo.vtax_tags (juris_tax_nkid,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT distinct j.nkid, t.id, t.name, t.tag_type_id, ptt.entered_by, ptt.entered_date, ptt.status
FROM juris_tax_imposition_tags ptt
join tags t on (t.id = ptt.tag_id)
JOIN juris_tax_impositions j ON (j.nkid = ptt.ref_nkid)
 
 
 ;