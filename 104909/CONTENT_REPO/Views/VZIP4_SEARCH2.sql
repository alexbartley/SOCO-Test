CREATE OR REPLACE FORCE VIEW content_repo.vzip4_search2 ("ID",state_name,county_name,city_name,zip,plus4_range,default_flag,unique_area_id,unique_area_rid,unique_area,rid,nkid,next_rid,usps_start_date,usps_end_date,state_code) AS
(
     SELECT
          p.id,
          u.state_name,
          u.county_name,
          u.city_name city_name,
          NVL (u.zip, '-') zip,
          NVL (SUBSTR(u.zip9, 6, 4), '-') plus4_range,
          CASE WHEN u.override_rank = 1 THEN 'Yes' ELSE 'No' END
             default_flag,
          gua2.id,
          gua2.rid,
          gua.unique_area,
          p.rid,
          p.nkid,
          p.next_rid,
          u.start_date,
          u.end_date,
          u.state_code
     FROM geo_usps_lookup u
          JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
          JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                            AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
          JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
          JOIN geo_unique_areas gua2 ON (u.area_id = gua2.area_id)  -- 10/08/15 - changed from gua.area_id
          LEFT JOIN vgeo_unique_areas2 gua ON (    u.state_code   = gua.state_code
                                               AND u.county_name  = gua.county_name
                                               AND u.city_name    = gua.city_name
                                               AND NVL(u.zip, -1) = NVL (gua.zip, -1)
                                               AND NVL2(SUBSTR(u.zip9, 6, 4), (u.zip || SUBSTR(u.zip9, 6, 4)), -1) = NVL(gua.zip9, -1)
                                               AND u.area_id = gua.area_id -- crapp_2026
                                              )
)
 
 ;