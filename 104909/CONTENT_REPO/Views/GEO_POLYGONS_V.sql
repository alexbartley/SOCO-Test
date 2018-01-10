CREATE OR REPLACE FORCE VIEW content_repo.geo_polygons_v ("ID",geo_area_key,hierarchy_level,geo_area_id,geo_area,polygon_type_id,polygon_type,polygon_start_date,polygon_end_date,polygon_status,polygon_status_date,state_code,state_name,state_fips,county_name,county_fips,city_name,city_fips,zip,plus4_range,zip9,default_flag,override_rank,usps_start_date,usps_end_date,code_fips,stj_fips,official_name,unique_area,rid,nkid,next_rid) AS
SELECT  DISTINCT
            p.id,
            p.geo_area_key,
            p.hierarchy_level_id,
            ac.id   geo_area_id,
            ac.NAME  geo_area,
            pt.id   polyton_type_id,
            pt.NAME  polygon_type,
            p.start_date polygon_start_date,
            p.end_date   polygon_end_date,        
            p.status polygon_status,
            p.status_modified_date  polygon_status_date, 
            u.state_code,           
            u.state_name,
            u.state_fips,
            u.county_name,
            u.county_fips,            
            NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name)    city_name,
            NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips) city_fips,
            u.zip,
            u.plus4_range,
            NVL2(u.plus4_range, (u.zip || u.plus4_range), NULL) zip9,
            CASE WHEN ua.override_rank = 1 THEN 'Y'
                 ELSE NULL
            END default_flag,
            ua.override_rank,
            u.start_date usps_start_date,
            u.end_date   usps_end_date,
            (u.state_fips || u.county_fips || NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips) || NVL(u.zip,'')) code_fips,
            CASE WHEN ac.name = 'District' THEN SUBSTR(p.geo_area_key, 4, INSTR(p.geo_area_key, '-', 4, 1)-4) 
                 ELSE NULL
            END stj_fips,
            UPPER(SUBSTR(p.geo_area_key, 1, 2) || ' - ' || SUBSTR(p.geo_area_key, INSTR(p.geo_area_key, '-', 4, 1)+1)) official_name,            
            
            CASE WHEN u.zip IS NOT NULL 
                 THEN NVL(d.unique_area, (u.state_code||'-'||u.state_fips||'-'||u.state_name||'|'||
                                          u.state_code||'-'||u.county_fips||'-'||u.county_name||'|'||
                                          u.state_code||'-'||CASE WHEN NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips) = '99999' 
                                                                  THEN u.county_fips||'-'||u.county_name||'-Unincorporated'
                                                                  ELSE NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips)||'-'||NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name)
                                                             END))
                 WHEN u.zip IS NULL AND ac.NAME = 'District'   
                 THEN (u.state_code||'-'||u.state_fips||'-'||u.state_name||'|'||
                       u.state_code||'-'||u.county_fips||'-'||u.county_name||'|'||
                       u.state_code||'-'||CASE WHEN NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips) = '99999' 
                                               THEN u.county_fips||'-'||u.county_name||'-Unincorporated'
                                               ELSE NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips)||'-'||NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name)
                                          END||'|'||p.geo_area_key)
                                           
                 ELSE (u.state_code||'-'||u.state_fips||'-'||u.state_name||'|'||
                       u.state_code||'-'||u.county_fips||'-'||u.county_name||'|'||
                       u.state_code||'-'||CASE WHEN NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips) = '99999' 
                                               THEN u.county_fips||'-'||u.county_name||'-Unincorporated'
                                               ELSE NVL2(ua.id, TRIM(SUBSTR(ua.value, 1, 6)), u.city_fips)||'-'||NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name)
                                          END) 
             END unique_area,
             p.rid,
             p.nkid,
             p.next_rid
           
    FROM    geo_polygon_usps u
            JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
            
            JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                              AND rev_join (p.rid, r.id, COALESCE(p.next_rid, 999999999)) = 1)
                
            JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
            JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
            JOIN geo_polygon_types pt ON (p.geo_polygon_type_id = pt.id)
            
            LEFT JOIN gis_usps_attributes ua ON (u.id = ua.geo_polygon_usps_id)
            LEFT JOIN additional_attributes aa ON (ua.attribute_id = aa.id)
            
            LEFT JOIN geo_district_areas_v d ON ( u.state_code = d.state_code
                                                  AND u.county_name = d.county_name
                                                  AND NVL2(ua.id, SUBSTR(ua.value, 7), u.city_name) = d.city_name
                                                  AND NVL(u.zip, -1) = NVL(d.zip, -1)
                                                  AND NVL2(u.plus4_range, (u.zip || u.plus4_range), -1)  = NVL(d.zip9, -1)
                                                  AND CASE WHEN ua.override_rank = 1 THEN 'Y' ELSE 'N' END = d.default_flag
                                                )
 
 ;