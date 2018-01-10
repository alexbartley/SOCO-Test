CREATE OR REPLACE FORCE VIEW content_repo.vgeo_poly_ids_kpmg ("ID",nkid,rid) AS
SELECT DISTINCT
    id,
    nkid,
    rid
FROM
    geo_polygons
 
 ;