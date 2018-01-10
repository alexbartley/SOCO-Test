CREATE OR REPLACE FORCE VIEW content_repo.vattachment_tags ("ID",att_id,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT DISTINCT ptt.id, ad.id, t.id, t.name, t.tag_type_id, ptt.entered_by, ptt.entered_date, ptt.status
FROM attachment_tags ptt
join tags t on (t.id = ptt.tag_id)
JOIN attachments ad on (ad.id = ptt.attachment_id)
 
 
 ;