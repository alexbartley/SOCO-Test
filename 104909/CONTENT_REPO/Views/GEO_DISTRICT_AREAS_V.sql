CREATE OR REPLACE FORCE VIEW content_repo.geo_district_areas_v (geo_area_key,state_code,county_name,city_name,zip,zip9,stj_fips,unique_area,default_flag,rid,nkid,next_rid) AS
SELECT  DISTINCT
            p.geo_area_key,
            u.state_code,
            u.county_name,
            NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name) city_name,
            u.zip,
            NVL2(u.plus4_range, (u.zip || u.plus4_range), NULL) zip9,
            SUBSTR(p.geo_area_key, 4, INSTR(p.geo_area_key, '-', 4, 1)-4) stj_fips,
            ( u.state_code||'-'||u.state_fips||'-'||u.state_name||'|'||
              u.state_code||'-'||u.county_fips||'-'||u.county_name||'|'||
              u.state_code||'-'||CASE WHEN NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips) = '99999' 
                                      THEN u.county_fips||'-'||u.county_name||'-Unincorporated'
                                      ELSE NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips)||'-'||NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name)
                                 END||'|'|| p.geo_area_key)  unique_area,
            CASE WHEN ua.override_rank = 1 THEN 'Y'
                 ELSE 'N'
            END default_flag,
            p.rid,
            p.nkid,
            p.next_rid
            
    FROM    geo_poly_ref_revisions r

            JOIN geo_polygons p ON (    r.nkid = p.nkid
                                    AND rev_join (p.rid, r.id, COALESCE(p.next_rid, 999999999)) = 1)
    
            JOIN geo_polygon_usps u ON (p.id = u.geo_polygon_id)            
            JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
            JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
            LEFT JOIN gis_usps_attributes ua ON (u.id = ua.geo_polygon_usps_id)
    WHERE   ac.NAME = 'District'
 
 ;