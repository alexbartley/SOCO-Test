CREATE OR REPLACE FORCE VIEW content_repo.vjuris_geo_areas ("ID",nkid,rid,next_rid,geo_area_rid,geo_area_next_rid,juris_entity_rid,juris_entity_next_rid,jurisdiction_nkid,jurisdiction_id,official_name,description,start_date,end_date,status,status_modified_date,entered_by,entered_date,state_code,geo_polygon_id,geo_polygon_rid,requires_establishment,poly_start_date,poly_end_date) AS
SELECT DISTINCT
          ja.id
          , ja.nkid
          , ja.rid
          , ja.next_rid
          , r.id          geo_area_rid
          , r.next_rid    geo_area_next_rid
          , j.rid         juris_entity_rid
          , j.next_rid    juris_entity_next_rid
          , j.nkid        jurisdiction_nkid
          , j.id          jurisdiction_id
          , j.official_name
          , j.description
          , TO_CHAR (ja.start_date, 'mm/dd/yyyy') start_date
          , TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date
          , ja.status
          , ja.status_modified_date
          , ja.entered_by
          , ja.entered_date
          --, SUBSTR (j.official_name, 1, 2) state_code      -- removed crapp-2097
          , sc.state_code                                    -- added crapp-2097
          , ja.geo_polygon_id
          , gp.rid        geo_polygon_rid
          , ja.requires_establishment
          , TO_CHAR (gp.start_date, 'mm/dd/yyyy') poly_start_date   -- 02/11/16 - added
          , TO_CHAR (gp.end_date, 'mm/dd/yyyy') poly_end_date          
    FROM  juris_geo_areas ja
    JOIN  vgeo_poly_ids jpi ON (jpi.id = ja.geo_polygon_id)
          JOIN geo_poly_ref_revisions r ON (    r.nkid = jpi.nkid
                                            AND rev_join (ja.rid, r.id, COALESCE(ja.next_rid, 999999999)) = 1)
          JOIN jurisdictions j ON (ja.jurisdiction_nkid = j.nkid)       -- (ja.jurisdiction_id = j.id) -- changed 08/06/15 crapp-1981
          JOIN geo_polygons gp ON (ja.geo_polygon_nkid = gp.nkid)
          
          -- added crapp-2097
          JOIN (
                SELECT uasc.state_code, gp.*
                FROM   vunique_area_polygons gp 
                       JOIN (
                             SELECT DISTINCT 
                                    uap.unique_area_rid
                                    , uap.polygon 
                                    , SUBSTR(uap.polygon, 1, 2) state_code
                             FROM   vunique_area_polygons uap
                                    JOIN geo_polygons p ON uap.poly_nkid = p.nkid
                             WHERE  p.next_rid IS NULL
                                    AND p.hierarchy_level_id = 4 -- State Level      
                            ) uasc ON gp.unique_area_rid = uasc.unique_area_rid
               ) sc ON jpi.nkid = sc.poly_nkid

     WHERE j.next_rid IS NULL   -- added 08/06/15 crapp-1981;;;
;