CREATE OR REPLACE FORCE VIEW content_repo.vgeo_polygons_search ("ID",geo_area_key,hierarchy_level,geo_area_id,geo_area,polygon_type_id,polygon_type,polygon_start_date,polygon_end_date,polygon_status,polygon_status_date,state_code,state_name,state_fips,county_name,county_fips,city_name,city_fips,zip,plus4_range,zip9,default_flag,override_rank,usps_start_date,usps_end_date,code_fips,stj_fips,official_name,unique_area,area_id,rid,nkid,next_rid) AS
SELECT /*+index(p geo_polygons_un)*/
          p.id,
          p.geo_area_key,
          p.hierarchy_level_id,
          ac.id        geo_area_id,
          ac.NAME      geo_area,
          pt.id        polyton_type_id,
          pt.NAME      polygon_type,
          p.start_date polygon_start_date,
          p.end_date   polygon_end_date,
          p.status     polygon_status,
          p.status_modified_date polygon_status_date,
          u.state_code,
          u.state_name,
          u.state_fips,
          u.county_name,
          u.county_fips,
          u.city_name,
          u.city_fips,
          u.zip,
          SUBSTR(u.zip9, 6, 4) plus4_range,
          u.zip9,
          CASE WHEN u.override_rank = 1 THEN 'Y' ELSE NULL END default_flag,
          u.override_rank,
          u.start_date usps_start_date,
          u.end_date   usps_end_date,
          (   u.state_fips
           || u.county_fips
           || u.city_fips
           || NVL (u.zip, '')) code_fips,
          CASE WHEN ac.name = 'District' THEN SUBSTR (p.geo_area_key, 4, INSTR (p.geo_area_key, '-', 4, 1) - 4)
               ELSE NULL
          END stj_fips,
          UPPER (   SUBSTR (p.geo_area_key, 1, 2)
                 || ' - '
                 || SUBSTR (p.geo_area_key, INSTR (p.geo_area_key, '-', 4, 1) + 1)) official_name,
          gua.unique_area,
          gua.area_id,
          p.rid,
          p.nkid,
          p.next_rid
     FROM geo_usps_lookup u
          JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
          JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                            AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
          JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
          JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
          JOIN geo_polygon_types pt ON (p.geo_polygon_type_id = pt.id)
          LEFT JOIN vgeo_unique_areas2 gua ON (    u.state_code   = gua.state_code
                                               AND u.county_name  = gua.county_name
                                               AND u.city_name    = gua.city_name
                                               AND NVL(u.zip, -1) = NVL (gua.zip, -1)
                                               AND NVL2(SUBSTR(u.zip9, 6, 4), (u.zip || SUBSTR(u.zip9, 6, 4)), -1) = NVL(gua.zip9, -1)
                                               AND u.area_id = gua.area_id
                                              )
     WHERE u.state_code IS NOT NULL
 
 ;