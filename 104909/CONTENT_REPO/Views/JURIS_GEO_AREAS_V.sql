CREATE OR REPLACE FORCE VIEW content_repo.juris_geo_areas_v ("ID",nkid,rid,next_rid,juris_area_rid,juris_area_next_rid,juris_entity_rid,juris_entity_next_rid,official_name,description,location_category_id,location_category,geo_polygon_id,geo_area_key,geo_area_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,state_code) AS
SELECT ja.id,
          ja.nkid,
          ja.rid,
          ja.next_rid,          
          r.id        juris_area_rid,
          r.next_rid  juris_area_next_rid,
          j.rid       juris_entity_rid,
          j.next_rid  juris_entity_next_rid,
          j.official_name,
          j.description,
          lc.id    location_category_id,
          lc.name  location_category,
          g.id     geo_polygon_id,
          g.geo_area_key,
          NULL geo_area_id, -- can't remember why this is here
          TO_CHAR (ja.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ja.end_date, 'mm/dd/yyyy')   end_date,
          ja.status,
          ja.status_modified_date,
          ja.entered_by,
          ja.entered_date,
          SUBSTR(j.official_name, 1, 2) state_code
          
     FROM geo_poly_ref_revisions r
          
          JOIN juris_geo_areas ja ON (    r.nkid = ja.nkid
                                      AND rev_join (ja.rid, r.id, COALESCE(ja.next_rid, 999999999)) = 1)
                 
          JOIN jurisdictions j ON (ja.jurisdiction_id = j.id)
          
          JOIN geo_polygons g ON (ja.geo_polygon_id = g.id)       
          JOIN geo_area_categories lc ON (lc.id = j.geo_area_category_id);