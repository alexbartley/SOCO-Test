CREATE OR REPLACE FORCE VIEW content_repo.vunique_area_tags (nkid,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT DISTINCT gua.nkid,
                   t.id TAG_ID,
                   t.name TAG,
                   t.tag_type_id,
                   guat.entered_by,
                   guat.entered_date,
                   guat.status
     FROM geo_unique_area_tags guat
          JOIN tags t
             ON (t.id = guat.tag_id)
          JOIN geo_unique_areas gua
             ON (gua.nkid = guat.ref_nkid)
 
 ;