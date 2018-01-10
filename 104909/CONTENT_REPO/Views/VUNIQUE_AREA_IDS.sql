CREATE OR REPLACE FORCE VIEW content_repo.vunique_area_ids ("ID",nkid) AS
SELECT DISTINCT id, nkid FROM geo_unique_areas
 
 ;