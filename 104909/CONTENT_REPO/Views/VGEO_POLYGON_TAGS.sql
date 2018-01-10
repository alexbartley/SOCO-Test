CREATE OR REPLACE FORCE VIEW content_repo.vgeo_polygon_tags (nkid,tag_id,"TAG",tag_type_id,entered_by,entered_date,status) AS
SELECT  DISTINCT
        p.nkid,
        t.id     TAG_ID,
        t.name   TAG,
        t.tag_type_id,
        ptt.entered_by,
        ptt.entered_date,
        ptt.status
FROM    geo_polygon_tags ptt
        JOIN tags t on (t.id = ptt.tag_id)
        JOIN geo_polygons p on (p.nkid = ptt.ref_nkid)
 
 ;