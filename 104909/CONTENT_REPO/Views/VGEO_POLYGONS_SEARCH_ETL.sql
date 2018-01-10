CREATE OR REPLACE FORCE VIEW content_repo.vgeo_polygons_search_etl (geo_area,state_code,state_name,county_name,city_name,zip,plus4_range,zip9,default_flag,code_fips,official_name,rid,nkid,next_rid) AS
SELECT /*+index (p geo_polygons_un) */
          ac.NAME geo_area,
          u.state_code,
          u.state_name,
          u.county_name,
          u.city_name,
          u.zip,
          SUBSTR(u.zip9, 6, 4) plus4_range,
          u.zip9,
          CASE WHEN u.override_rank = 1 THEN 'Y' ELSE NULL END default_flag,
          (u.state_fips || u.county_fips || u.city_fips || NVL (u.zip, '')) code_fips,
          UPPER( SUBSTR (p.geo_area_key, 1, 2) || ' - ' || SUBSTR (p.geo_area_key, INSTR (p.geo_area_key, '-', 4, 1) + 1)) official_name,
          p.rid,
          p.nkid,
          p.next_rid
          
     FROM geo_usps_lookup u
     
          JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
          
          JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                            AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
          
          JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
          
          JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
 ;