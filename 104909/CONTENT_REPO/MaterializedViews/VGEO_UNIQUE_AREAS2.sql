CREATE MATERIALIZED VIEW content_repo.vgeo_unique_areas2
ON PREBUILT TABLE
REFRESH FAST 
ENABLE QUERY REWRITE
AS SELECT zip
           , zip9
           , state_code
           , state_name
           , county_name
           , city_name
           , LISTAGG ( geo_area_key, '|')
                       WITHIN GROUP (ORDER BY ( state_fips || hierarchy_level_id || area_id || NVL(stj_fips, '99999'))) unique_area
           , area_id
    FROM geo_usps_mv_staging
    GROUP BY state_code
             , zip
             , county_name
             , city_name
             , zip9
             , area_id
             , state_name;