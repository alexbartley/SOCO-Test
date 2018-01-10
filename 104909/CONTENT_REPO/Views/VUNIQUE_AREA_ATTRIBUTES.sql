CREATE OR REPLACE FORCE VIEW content_repo.vunique_area_attributes ("ID",nkid,rid,next_rid,unique_area_id,unique_area_nkid,unique_area_rid,unique_area_next_rid,attribute_category,attribute_category_id,"VALUE",value_id,attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT guaa.id,
          guaa.nkid,
          guaa.rid,
          guaa.next_rid,
          uai.id,
          uai.nkid,
          guar.id,
          guar.next_rid,
          ac.name,
          ac.id,
          COALESCE(j.official_name, guaa.VALUE) value,
          CASE WHEN j.official_name IS NULL THEN TO_CHAR(guaa.geo_unique_area_id)
               ELSE guaa.VALUE
          END  value_id,
          aa.name,
          aa.id,
          TO_CHAR (guaa.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (guaa.end_date, 'mm/dd/yyyy') end_date,
          guaa.status,
          guaa.status_modified_date,
          guaa.entered_by,
          guaa.entered_date
     FROM GEO_UNIQUE_AREA_ATTRIBUTES guaa
          JOIN VUNIQUE_AREA_IDS uai ON (uai.id = guaa.GEO_UNIQUE_AREA_ID)
          JOIN GEO_UNIQUE_AREA_revisions guar ON (    guar.nkid = uai.nkid
                                                  AND rev_join (guaa.rid,guar.id, COALESCE(guaa.next_rid, 99999999)) = 1)
          JOIN additional_attributes aa ON (aa.id = guaa.attribute_id)
          JOIN attribute_categories ac ON (ac.id = aa.attribute_category_id)
          LEFT JOIN jurisdictions j ON (guaa.value = j.nkid
                                        AND j.next_rid IS NULL)
 
 ;