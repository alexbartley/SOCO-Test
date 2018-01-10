CREATE OR REPLACE FORCE VIEW content_repo.vunique_area_polygons (unique_area_rid,poly_rid,poly_nkid,poly_next_rid,polygon) AS
SELECT gua.rid,
          gp.rid,
          gp.nkid,
          gp.next_rid,
          GP.GEO_AREA_KEY
     FROM geo_unique_areas gua
          JOIN geo_unique_area_polygons guap
             ON gua.id = GUAP.UNIQUE_AREA_ID
          JOIN geo_polygons gp
             ON (guap.geo_polygon_id = gp.id)
    ORDER BY GP.HIERARCHY_LEVEL_ID
 
 ;