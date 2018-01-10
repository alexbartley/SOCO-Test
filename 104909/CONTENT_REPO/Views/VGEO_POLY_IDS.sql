CREATE OR REPLACE FORCE VIEW content_repo.vgeo_poly_ids ("ID",nkid) AS
SELECT DISTINCT id, nkid FROM geo_polygons
 
 ;