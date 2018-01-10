CREATE OR REPLACE FORCE VIEW content_repo.vunique_areas (unique_area,start_date,end_date,"ID",rid,nkid,next_rid) AS
SELECT /*+index(u geo_unique_area_polygons_n1) index(a geo_unique_areas_pk) index(p geo_polygons_pk)*/
         DISTINCT ua.unique_area,
                  TO_CHAR (a.start_date, 'mm/dd/yyyy') start_date,
                  TO_CHAR (a.end_date, 'mm/dd/yyyy') end_date,
                  a.id,
                  a.rid,
                  a.nkid,
                  a.next_rid
     FROM geo_unique_area_polygons u
          JOIN geo_unique_areas a
             ON (u.unique_area_id = a.id)
          JOIN (SELECT DISTINCT
                       state_code,
                          area_id,                                 -- HASH_MD4
                       unique_area
                  FROM vgeo_unique_areas2) ua
             ON (a.area_id = ua.area_id)
 
 ;