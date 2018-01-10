CREATE OR REPLACE PACKAGE BODY content_repo."LOAD_GIS"
IS

    -- ***************************** --
    -- Load Initial GIS Data into CR --
    -- ***************************** --
    PROCEDURE master_data (stcode_i IN VARCHAR2, user_i IN NUMBER, job_id_i IN NUMBER) -- crapp-3451
    IS
            l_log_id NUMBER;
            l_rec    NUMBER := 0;
            l_pID    NUMBER := gis_etl_process_log_sq.nextval;
            l_stfips VARCHAR2(2 CHAR);
            l_stname VARCHAR2(50 CHAR);

        BEGIN

            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'master_data', paction=>0, puser=>user_i);

            SELECT DISTINCT
                   fips   stfips
                   ,name  stname
            INTO   l_stfips, l_stname
            FROM   geo_states
            WHERE  state_code = stcode_i;

            dbms_output.put_line (stcode_i ||'-'|| l_stfips ||'-'|| l_stname);

            INSERT INTO geo_load_log(state_code, start_time, initial_count, failure_count, success_count, entered_by, import_type, job_id)
            VALUES (stcode_i, SYSTIMESTAMP, 0, 0, 0, user_i, 'M', job_id_i) RETURNING id INTO l_log_id;
            COMMIT;

            l_rec := l_rec + load_gis.extract_gis_areas (stcode_i, l_stname, user_i, l_pID);
            dbms_output.put_line (' - Extracted Zip9 from GIS');
            UPDATE geo_load_log
                SET extract_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            -- crapp-3070 --
            load_gis.extract_mailing_city (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Mailing Cities extracted');

            l_rec := l_rec + load_gis.create_geo_polygons (stcode_i, l_stfips, l_stname, user_i, l_pID);
            dbms_output.put_line (' - Polygons created');
            UPDATE geo_load_log
                SET polygon_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            load_gis.update_ranking (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Ranking complete');
            UPDATE geo_load_log
                SET ranking_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            l_rec := l_rec + load_gis.update_geo_polygon_usps (stcode_i, user_i, l_pID, 'M');
            dbms_output.put_line (' - USPS created');
            UPDATE geo_load_log
                SET usps_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            load_gis.create_unique_areas (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Unique Areas created');


            map_juris_geo_areas (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Inital Area Mappings created');

            -- Archive UA_Zip9 table --
            archive_uaz9 (stcode_i, user_i, l_pID);  -- crapp-3451
            dbms_output.put_line (' - UA_Zip9 archived');

            UPDATE geo_load_log
                SET areas_stop_time = SYSTIMESTAMP,
                    initial_count = l_rec,
                    stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;

            COMMIT;
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'master_data', paction=>1, puser=>user_i);
        END master_data;


    -- *********************************************************** --
    -- Process to load GIS Data changed since initial load into CR --
    -- *********************************************************** --
    PROCEDURE update_data (stcode_i IN VARCHAR2, user_i IN NUMBER, job_id_i IN NUMBER)  -- crapp-3451
    IS
            l_log_id   NUMBER;
            l_recs     NUMBER := 0;
            l_total    NUMBER := 0;
            l_pID      NUMBER := gis_etl_process_log_sq.nextval;
            l_stfips   VARCHAR2(2 CHAR);
            l_stname   VARCHAR2(50 CHAR);

        BEGIN

            gis_etl_p(l_pID, stcode_i, 'update_data', 0, user_i);

            SELECT DISTINCT
                   fips   stfips
                   ,name  stname
            INTO   l_stfips, l_stname
            FROM   geo_states
            WHERE  state_code = stcode_i;

            dbms_output.put_line (stcode_i ||'-'|| l_stfips ||'-'|| l_stname);

            INSERT INTO geo_load_log(state_code, start_time, initial_count, failure_count, success_count, entered_by, import_type, job_id)
            VALUES (stcode_i, SYSTIMESTAMP, 0, 0, 0, user_i, 'U', job_id_i) RETURNING id INTO l_log_id;
            COMMIT;

            -- Extract GIS Zip Areas --
            l_recs := l_recs + extract_gis_areas (stcode_i, l_stname, user_i, l_pID);
            dbms_output.put_line (' - Extracted Zip9 Areas from GIS');
            UPDATE geo_load_log
                SET extract_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            -- Extract Mailing Cities - crapp-3070 --
            extract_mailing_city (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Mailing Cities extracted');

            -- Update Polygons --
            l_recs := l_recs + update_geo_polygons (stcode_i, l_stname, user_i, l_pID);
            dbms_output.put_line (' - Polygons updated');
            UPDATE geo_load_log
                SET polygon_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            -- Determine ranking for defaults --
            update_ranking (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Ranking complete');
            UPDATE geo_load_log
                SET ranking_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            -- Populate USPS table with changes --
            l_recs := l_recs + update_geo_polygon_usps (stcode_i, user_i, l_pID, 'U');
            dbms_output.put_line (' - USPS updated');
            UPDATE geo_load_log
                SET usps_stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;
            COMMIT;

            -- Update Unique Areas --
            update_unique_areas (stcode_i, user_i, l_pID);
            dbms_output.put_line (' - Unique Areas updated');

            -- Archive UA_Zip9 table --
            archive_uaz9 (stcode_i, user_i, l_pID);  -- crapp-3451
            dbms_output.put_line (' - UA_Zip9 archived');

            UPDATE geo_load_log
                SET areas_stop_time = SYSTIMESTAMP,
                    initial_count = l_recs,
                    stop_time = SYSTIMESTAMP
            WHERE id = l_log_id;

            COMMIT;
            gis_etl_p(l_pID, stcode_i, 'update_data', 1, user_i);
        END update_data;



    -- ****************************************************** --
    -- Get ArcGIS records                                     --
    --      Zip9 into GIS_INDATA_AREAS_TEMP                   --
    --      Supplemental Areas into GIS_INDATA_AREAS_SUP_TEMP --
    -- ****************************************************** --
    FUNCTION extract_gis_areas (stcode_i IN VARCHAR2, stname_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) RETURN NUMBER    -- 10/18/17 crapp-3600
    IS
            l_sql      VARCHAR2(250 CHAR);
            l_status   NUMBER := 0;
            l_recs     NUMBER := 0;
            l_supp     NUMBER := 0;
            l_typeid   NUMBER;
            l_hlevelid NUMBER;

            TYPE t_indata IS TABLE OF gis_indata_areas_temp%ROWTYPE;
            v_indata t_indata;

            TYPE t_indatasup IS TABLE OF gis_indata_areas_sup_temp%ROWTYPE;
            v_indatasup t_indatasup;

            CURSOR indata IS
                SELECT zip, zip4, zip9, match, match_id, biti_id, state
                       , state_name, state_fips
                       , county_fips, UPPER(county_name) county_name
                       , city_fips, UPPER(city_name) city_name
                       , CASE WHEN stj1_id = '<Null>' THEN NULL ELSE stj1_id END stj1_id, UPPER(stj1_name) stj1_name
                       , CASE WHEN stj2_id = '<Null>' THEN NULL ELSE stj2_id END stj2_id, UPPER(stj2_name) stj2_name
                       , CASE WHEN stj3_id = '<Null>' THEN NULL ELSE stj3_id END stj3_id, UPPER(stj3_name) stj3_name
                       , CASE WHEN stj4_id = '<Null>' THEN NULL ELSE stj4_id END stj4_id, UPPER(stj4_name) stj4_name
                       , CASE WHEN stj5_id = '<Null>' THEN NULL ELSE stj5_id END stj5_id, UPPER(stj5_name) stj5_name
                       , CASE WHEN stj6_id = '<Null>' THEN NULL ELSE stj6_id END stj6_id, UPPER(stj6_name) stj6_name
                       , CASE WHEN stj7_id = '<Null>' THEN NULL ELSE stj7_id END stj7_id, UPPER(stj7_name) stj7_name
                       , CASE WHEN stj8_id = '<Null>' THEN NULL ELSE stj8_id END stj8_id, UPPER(stj8_name) stj8_name
                       , CASE WHEN stj9_id = '<Null>' THEN NULL ELSE stj9_id END stj9_id, UPPER(stj9_name) stj9_name
                       , UPPER(unique_area) unique_area
                       , 0 multiple_counties, 0 multiple_cities, 0 multiple_stjs, 0 county_rank, 0 city_rank
                       , NULL default_city, NULL default_zip, NULL default_zip4
                       , city_startdate, city_enddate, NULL revdate
                       , (state ||'-'|| state_fips ||'-'|| state_name) state_geo_area_key
                       , (state ||'-'|| county_fips ||'-'|| UPPER(county_name)) county_geo_area_key
                       , CASE WHEN city_name = 'UNINCORPORATED' THEN (state ||'-'|| county_fips ||'-'|| UPPER(county_name) ||'-'|| city_name)
                              ELSE (state ||'-'|| city_fips ||'-'|| UPPER(city_name))
                         END city_geo_area_key
                       , CASE WHEN stj1_id = '<Null>' OR stj1_id IS NULL THEN NULL ELSE (state ||'-'|| stj1_id ||'-'|| UPPER(stj1_name)) END stj1_geo_area_key
                       , CASE WHEN stj2_id = '<Null>' OR stj2_id IS NULL THEN NULL ELSE (state ||'-'|| stj2_id ||'-'|| UPPER(stj2_name)) END stj2_geo_area_key
                       , CASE WHEN stj3_id = '<Null>' OR stj3_id IS NULL THEN NULL ELSE (state ||'-'|| stj3_id ||'-'|| UPPER(stj3_name)) END stj3_geo_area_key
                       , CASE WHEN stj4_id = '<Null>' OR stj4_id IS NULL THEN NULL ELSE (state ||'-'|| stj4_id ||'-'|| UPPER(stj4_name)) END stj4_geo_area_key
                       , CASE WHEN stj5_id = '<Null>' OR stj5_id IS NULL THEN NULL ELSE (state ||'-'|| stj5_id ||'-'|| UPPER(stj5_name)) END stj5_geo_area_key
                       , CASE WHEN stj6_id = '<Null>' OR stj6_id IS NULL THEN NULL ELSE (state ||'-'|| stj6_id ||'-'|| UPPER(stj6_name)) END stj6_geo_area_key
                       , CASE WHEN stj7_id = '<Null>' OR stj7_id IS NULL THEN NULL ELSE (state ||'-'|| stj7_id ||'-'|| UPPER(stj7_name)) END stj7_geo_area_key
                       , CASE WHEN stj8_id = '<Null>' OR stj8_id IS NULL THEN NULL ELSE (state ||'-'|| stj8_id ||'-'|| UPPER(stj8_name)) END stj8_geo_area_key
                       , CASE WHEN stj9_id = '<Null>' OR stj9_id IS NULL THEN NULL ELSE (state ||'-'|| stj9_id ||'-'|| UPPER(stj9_name)) END stj9_geo_area_key
                       , NULL stj_name
                       , uaid
                       , stj1_enddate, stj2_enddate, stj3_enddate, stj4_enddate, stj5_enddate, stj6_enddate, stj7_enddate, stj8_enddate, stj9_enddate
                       , taxid
                       , stj1_startdate, stj2_startdate, stj3_startdate, stj4_startdate, stj5_startdate, stj6_startdate, stj7_startdate, stj8_startdate, stj9_startdate
                       , UPPER(city) city -- crapp-3070
                FROM gis_temp.tmp_gis_indata_areas@gis.corp.ositax.com;

            CURSOR indatasup IS
                SELECT zip, zip4, zip9, match, match_id, biti_id
                       , state, state_name, state_fips
                       , county_fips, UPPER(county_name) county_name
                       , city_fips, UPPER(city_name) city_name
                       , CASE WHEN stj1_id = '<Null>' THEN NULL ELSE stj1_id END stj1_id, UPPER(stj1_name) stj1_name
                       , CASE WHEN stj2_id = '<Null>' THEN NULL ELSE stj2_id END stj2_id, UPPER(stj2_name) stj2_name
                       , CASE WHEN stj3_id = '<Null>' THEN NULL ELSE stj3_id END stj3_id, UPPER(stj3_name) stj3_name
                       , CASE WHEN stj4_id = '<Null>' THEN NULL ELSE stj4_id END stj4_id, UPPER(stj4_name) stj4_name
                       , CASE WHEN stj5_id = '<Null>' THEN NULL ELSE stj5_id END stj5_id, UPPER(stj5_name) stj5_name
                       , CASE WHEN stj6_id = '<Null>' THEN NULL ELSE stj6_id END stj6_id, UPPER(stj6_name) stj6_name
                       , CASE WHEN stj7_id = '<Null>' THEN NULL ELSE stj7_id END stj7_id, UPPER(stj7_name) stj7_name
                       , CASE WHEN stj8_id = '<Null>' THEN NULL ELSE stj8_id END stj8_id, UPPER(stj8_name) stj8_name
                       , CASE WHEN stj9_id = '<Null>' THEN NULL ELSE stj9_id END stj9_id, UPPER(stj9_name) stj9_name
                       , uaid
                       , taxid
                       , UPPER(unique_area) unique_area
                       , 0 multiple_counties, 0 multiple_cities, 0 county_rank, 0 city_rank
                       , NULL default_city, NULL default_zip, NULL default_zip4
                       , city_startdate, city_enddate
                       , (state ||'-'|| state_fips ||'-'|| state_name) state_geo_area_key
                       , (state ||'-'|| county_fips ||'-'|| UPPER(county_name)) county_geo_area_key
                       , CASE WHEN city_name = 'UNINCORPORATED' THEN (state ||'-'|| county_fips ||'-'|| UPPER(county_name) ||'-'|| city_name)
                              ELSE (state ||'-'|| city_fips ||'-'|| UPPER(city_name))
                         END city_geo_area_key
                       , CASE WHEN stj1_id = '<Null>' OR stj1_id IS NULL THEN NULL ELSE (state ||'-'|| stj1_id ||'-'|| UPPER(stj1_name)) END stj1_geo_area_key
                       , CASE WHEN stj2_id = '<Null>' OR stj2_id IS NULL THEN NULL ELSE (state ||'-'|| stj2_id ||'-'|| UPPER(stj2_name)) END stj2_geo_area_key
                       , CASE WHEN stj3_id = '<Null>' OR stj3_id IS NULL THEN NULL ELSE (state ||'-'|| stj3_id ||'-'|| UPPER(stj3_name)) END stj3_geo_area_key
                       , CASE WHEN stj4_id = '<Null>' OR stj4_id IS NULL THEN NULL ELSE (state ||'-'|| stj4_id ||'-'|| UPPER(stj4_name)) END stj4_geo_area_key
                       , CASE WHEN stj5_id = '<Null>' OR stj5_id IS NULL THEN NULL ELSE (state ||'-'|| stj5_id ||'-'|| UPPER(stj5_name)) END stj5_geo_area_key
                       , CASE WHEN stj6_id = '<Null>' OR stj6_id IS NULL THEN NULL ELSE (state ||'-'|| stj6_id ||'-'|| UPPER(stj6_name)) END stj6_geo_area_key
                       , CASE WHEN stj7_id = '<Null>' OR stj7_id IS NULL THEN NULL ELSE (state ||'-'|| stj7_id ||'-'|| UPPER(stj7_name)) END stj7_geo_area_key
                       , CASE WHEN stj8_id = '<Null>' OR stj8_id IS NULL THEN NULL ELSE (state ||'-'|| stj8_id ||'-'|| UPPER(stj8_name)) END stj8_geo_area_key
                       , CASE WHEN stj9_id = '<Null>' OR stj9_id IS NULL THEN NULL ELSE (state ||'-'|| stj9_id ||'-'|| UPPER(stj9_name)) END stj9_geo_area_key
                       , NULL stj_name
                       , stj1_startdate, stj2_startdate, stj3_startdate, stj4_startdate, stj5_startdate, stj6_startdate, stj7_startdate, stj8_startdate, stj9_startdate
                       , stj1_enddate, stj2_enddate, stj3_enddate, stj4_enddate, stj5_enddate, stj6_enddate, stj7_enddate, stj8_enddate, stj9_enddate
                FROM gis_temp.tmp_gis_indata_areas_sup@gis.corp.ositax.com;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'extract_gis_areas', paction=>0, puser=>user_i);

            -- Call GIS procedure to extract the Zip data --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Call GIS package to extract Zip9 data, gis_export.load_gis_areas', paction=>0, puser=>user_i);
                gis.gis_export.load_gis_areas@gis.corp.ositax.com (stcode_i, stname_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Call GIS package to extract Zip9 data, gis_export.load_gis_areas', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate temp table with GIS data, gis_indata_areas_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_indata_areas_temp DROP STORAGE';

            -- Disable Indexes during insert --
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g3 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g4 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_n3 UNUSABLE';

            -- Copy GIS data to TDR staging table --
            -- 09/05/17 - converted to Limited Fetch insert for performance improvements --
            OPEN indata;
            LOOP
                FETCH indata BULK COLLECT INTO v_indata LIMIT 25000;

                FORALL i IN 1..v_indata.COUNT
                    INSERT INTO gis_indata_areas_temp
                    VALUES v_indata(i);
                COMMIT;

                EXIT WHEN indata%NOTFOUND;
            END LOOP;
            COMMIT;
            CLOSE indata;
            v_indata := t_indata();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate temp table with GIS data, gis_indata_areas_temp', paction=>1, puser=>user_i);

            -- Enable Indexes after insert --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats, gis_indata_areas_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g3 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_g4 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_temp_n3 REBUILD';

            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_indata_areas_temp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats, gis_indata_areas_temp', paction=>1, puser=>user_i);


            -- ************************************** --
            -- Update Stj_Name with Full list of STJs --
            -- ************************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate STJ_NAME with full list of STJs, gis_indata_areas_temp', paction=>0, puser=>user_i);
            UPDATE gis_indata_areas_temp
                SET stj_name = NVL2(stj1_name,
                                    NVL2(stj2_name,
                                    NVL2(stj3_name,
                                    NVL2(stj4_name,
                                    NVL2(stj5_name,
                                    NVL2(stj6_name,
                                    NVL2(stj7_name,
                                    NVL2(stj8_name,
                                    NVL2(stj9_name, (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name||'|'||stj7_name||'|'||stj8_name||'|'||stj9_name),
                                                    (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name||'|'||stj7_name||'|'||stj8_name)),
                                                    (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name||'|'||stj7_name)),
                                                    (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name)),
                                                    (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name)),
                                                    (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name)),
                                                    (stj1_name||'|'||stj2_name||'|'||stj3_name)),
                                                    (stj1_name||'|'||stj2_name)),
                                                    stj1_name), NULL)
            WHERE stj1_geo_area_key IS NOT NULL;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate STJ_NAME with full list of STJs, gis_indata_areas_temp', paction=>1, puser=>user_i);


            -- ****************************************** --
            -- Create any missing Unincorporated Polygons --
            -- ****************************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create any missing Unincorporated polygons, gis_indata_areas_temp', paction=>0, puser=>user_i);
            SELECT id
            INTO   l_typeid
            FROM   geo_polygon_types
            WHERE  name = 'STANDARD';   -- crapp-3600, changed to STANDARD from JURISDICTION

            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.name = 'City';

            INSERT INTO geo_polygons
                (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status)
                SELECT  DISTINCT
                        l_hlevelid  hierarchy_level_id
                        , (t.state ||'-'|| t.county_fips ||'-'||
                             TRIM(REPLACE(REPLACE(t.county_name, CHR(10), ''), CHR(13), '')) ||'-'||
                             TRIM(REPLACE(REPLACE(t.city_name, CHR(10), ''), CHR(13), '')) ) geo_area_key
                        , l_typeid    geo_polygon_type_id
                        , NVL(city_startdate, TO_DATE('01-Jan-2000')) start_date
                        , user_i   entered_by
                        , l_status
                FROM    gis_indata_areas_temp t
                WHERE   t.city_name = 'UNINCORPORATED'  -- now UPPER Case - crapp-2532
                        AND NOT EXISTS ( SELECT 1
                                         FROM   geo_polygons p
                                         WHERE  p.geo_area_key = (t.state ||'-'||
                                                                  t.county_fips ||'-'||
                                                                  TRIM(REPLACE(REPLACE(t.county_name, CHR(10), ''), CHR(13), '')) ||'-'||
                                                                  TRIM(REPLACE(REPLACE(t.city_name, CHR(10), ''), CHR(13), '')))
                                       );

            l_recs := l_recs + (SQL%ROWCOUNT);
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_polygons', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create any missing Unincorporated polygons, gis_indata_areas_temp', paction=>1, puser=>user_i);


            -- crapp-3560 - now processing Supplemental UAS in this procedure --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_indata_areas_sup_temp DROP STORAGE';

            -- Call GIS procedure to extract the Supplemental UAS data --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Call GIS package to extract supplemental_uas data, gis_export.load_gis_sup_areas', paction=>0, puser=>user_i);
                gis.gis_export.load_gis_sup_areas@gis.corp.ositax.com (stcode_i, stname_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Call GIS package to extract supplemental_uas data, gis_export.load_gis_sup_areas', paction=>1, puser=>user_i);


            -- Check to see if there are any supplemental records to process --
            SELECT COUNT(*)
            INTO   l_supp
            FROM   gis_temp.tmp_gis_indata_areas_sup@gis.corp.ositax.com
            WHERE  state = stcode_i;

            IF l_supp > 0 THEN -- Supplemental
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate temp table with supplemental_uas data - gis_indata_areas_sup_temp', paction=>0, puser=>user_i);

                -- Disable Indexes during insert --
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g1 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g2 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g3 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g4 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g5 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g6 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_n1 UNUSABLE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_n2 UNUSABLE';

                -- Copy GIS data to TDR staging table --
                -- 09/05/17 - converted to Limited Fetch insert for performance improvements --
                OPEN indatasup;
                LOOP
                    FETCH indatasup BULK COLLECT INTO v_indatasup LIMIT 25000;

                    FORALL i IN 1..v_indatasup.COUNT
                        INSERT INTO gis_indata_areas_sup_temp
                        VALUES v_indatasup(i);
                    COMMIT;

                    EXIT WHEN indatasup%NOTFOUND;
                END LOOP;
                COMMIT;
                CLOSE indatasup;
                v_indatasup := t_indatasup();
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate temp table with supplemental_uas data - gis_indata_areas_sup_temp', paction=>1, puser=>user_i);

                -- Enable Indexes after insert --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats, gis_indata_areas_sup_temp', paction=>0, puser=>user_i);
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g1 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g2 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g3 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g4 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g5 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_g6 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_n1 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_indata_areas_sup_temp_n2 REBUILD';

                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_indata_areas_sup_temp', cascade => TRUE);
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats, gis_indata_areas_sup_temp', paction=>1, puser=>user_i);


                -- ************************************** --
                -- Update Stj_Name with Full list of STJs --
                -- ************************************** --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate STJ_NAME with full list of STJs - gis_indata_areas_sup_temp', paction=>0, puser=>user_i);
                UPDATE gis_indata_areas_sup_temp
                    SET stj_name = NVL2(stj1_name,
                                        NVL2(stj2_name,
                                        NVL2(stj3_name,
                                        NVL2(stj4_name,
                                        NVL2(stj5_name,
                                        NVL2(stj6_name,
                                        NVL2(stj7_name,
                                        NVL2(stj8_name,
                                        NVL2(stj9_name, (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name||'|'||stj7_name||'|'||stj8_name||'|'||stj9_name),
                                                        (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name||'|'||stj7_name||'|'||stj8_name)),
                                                        (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name||'|'||stj7_name)),
                                                        (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name||'|'||stj6_name)),
                                                        (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name||'|'||stj5_name)),
                                                        (stj1_name||'|'||stj2_name||'|'||stj3_name||'|'||stj4_name)),
                                                        (stj1_name||'|'||stj2_name||'|'||stj3_name)),
                                                        (stj1_name||'|'||stj2_name)),
                                                        stj1_name), NULL)
                WHERE stj1_geo_area_key IS NOT NULL;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate STJ_NAME with full list of STJs - gis_indata_areas_sup_temp', paction=>1, puser=>user_i);
            END IF; -- Supplemental

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'extract_gis_areas', paction=>1, puser=>user_i);

            RETURN (l_recs + l_supp);
        END extract_gis_areas;



    -- ************************************************************* --
    -- Extract the Acceptable Mailing City for UNINCORPORATED cities --
    -- ************************************************************* --
    PROCEDURE extract_mailing_city (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) IS
            l_rec NUMBER := 0;
        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'extract_mailing_city', paction=>0, puser=>user_i);

            -- Verify there are records in GIS for this state --
            SELECT COUNT(*) recs
            INTO l_rec
            FROM gis.usps_ctystate_mailing@GIS.CORP.OSITAX.COM
            WHERE state_code = stcode_i;

            IF l_rec > 0 THEN
                -- Remove previous extracted records --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove previous extracted records', paction=>0, puser=>user_i);
                DELETE FROM geo_usps_mailing_city
                WHERE  state_code = stcode_i;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove previous extracted records', paction=>1, puser=>user_i);

                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get current acceptable mailing city records', paction=>0, puser=>user_i);
                EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_mailing_city_n1 UNUSABLE';
                INSERT INTO geo_usps_mailing_city
                    (state_code, zip, city_name, county_name, county_fips)
                    SELECT state_code
                           , zip_code zip
                           , UPPER(city_name) city_name
                           , UPPER(county_name) county_name
                           , county_fips
                    FROM   gis.usps_ctystate_mailing@GIS.CORP.OSITAX.COM
                    WHERE  state_code = stcode_i
                    ORDER BY state_code, zip_code;
                COMMIT;

                EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_mailing_city_n1 REBUILD';
                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_polygons', cascade => TRUE);
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get current acceptable mailing city records', paction=>1, puser=>user_i);
            END IF;

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'extract_mailing_city', paction=>1, puser=>user_i);
        END extract_mailing_city;



    -- ***************************************************** --
    -- Load GEO Polygons from GIS database into Content Repo --
    -- CRAPP-2145 - NULL START_DATE values will default to   --
    --   01/01/2000. Handled in the trigger INS_GEO_POLYGONS --
    -- ***************************************************** --
    FUNCTION create_geo_polygons (stcode_i IN VARCHAR2, stfips_i IN VARCHAR2, stname_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) RETURN NUMBER -- crapp-3600
    IS
                l_stmt     VARCHAR2(1000 CHAR);
                l_status   NUMBER := 0;
                l_recs     NUMBER := 0;
                l_typeid   NUMBER;
                l_hlevelid NUMBER;

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'create_geo_polygons', paction=>0, puser=>user_i);

            -- Make sure all indexes used are valid --
            EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_n3 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_pk REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_un REBUILD';

            SELECT id
            INTO   l_typeid
            FROM   geo_polygon_types
            WHERE  NAME = 'STANDARD';   -- crapp-3600, changed to STANDARD from JURISDICTION

            -- ***************** --
            -- Import State Data --
            -- ***************** --
            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'State';

            l_stmt := 'INSERT INTO geo_polygons '||
                        '(hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status) '||
                        'SELECT DISTINCT '||
                               l_hlevelid || ' hierarchy_level_id, '||
                               'state_geo_area_key geo_area_key, '||
                               l_typeid || ' geo_polygon_type_id, '||
                               'NULL start_date, '||
                               user_i || ' entered_by, '||
                               l_status || ' status '||
                        'FROM  gis_indata_areas_temp g '||
                        'WHERE state = ''' || stcode_i || ''' '||
                              'AND state_geo_area_key IS NOT NULL '||
                              'AND NOT EXISTS ( SELECT 1 '||
                                               'FROM   geo_polygons p '||
                                               'WHERE  p.geo_area_key = g.state_geo_area_key '||
                                             ')';

            EXECUTE IMMEDIATE l_stmt;
            l_recs := l_recs + (SQL%ROWCOUNT);
            COMMIT;


            -- ****************** --
            -- Import County Data --
            -- ****************** --
            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'County';

            l_stmt := 'INSERT INTO geo_polygons '||
                        '(hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status) '||
                        'SELECT DISTINCT '||
                                l_hlevelid || ' hierarchy_level_id, '||
                                'county_geo_area_key geo_area_key, '||
                                l_typeid || ' geo_polygon_type_id, '||
                                'NULL start_date, '||
                                user_i || ' entered_by, '||
                                l_status || ' status '||
                        'FROM   gis_indata_areas_temp g '||
                        'WHERE  state = ''' || stcode_i || ''' '||
                               'AND county_geo_area_key IS NOT NULL '||
                               'AND NOT EXISTS ( SELECT 1 '||
                                                'FROM   geo_polygons p '||
                                                'WHERE  p.geo_area_key = g.county_geo_area_key '||
                                              ')';

            EXECUTE IMMEDIATE l_stmt;
            l_recs := l_recs + (SQL%ROWCOUNT);
            COMMIT;


            -- **************** --
            -- Import City Data --
            -- **************** --
            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'City';

            l_stmt := 'INSERT INTO geo_polygons '||
                        '(hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status) '||
                        'SELECT DISTINCT '||
                                l_hlevelid || ' hierarchy_level_id, '||
                                'city_geo_area_key geo_area_key, '||
                                l_typeid || ' geo_polygon_type_id, '||
                                'NVL(g.city_startdate, TO_DATE(''01-Jan-2000'')) start_date, '||
                                user_i || ' entered_by, '||
                                l_status || ' status '||
                        'FROM   gis_indata_areas_temp g '||
                        'WHERE  state = ''' || stcode_i || ''' '||
                               'AND city_geo_area_key IS NOT NULL '||
                               'AND NOT EXISTS ( SELECT 1 '||
                                                'FROM   geo_polygons p '||
                                                'WHERE  p.geo_area_key = g.city_geo_area_key '||
                                              ')';

            EXECUTE IMMEDIATE l_stmt;
            l_recs := l_recs + (SQL%ROWCOUNT);
            COMMIT;


            -- *************** --
            -- Import STJ Data --
            -- *************** --
            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'District';

            FOR i IN 1..9 LOOP <<stj_loop>>
                l_stmt := 'INSERT INTO geo_polygons '||
                            '(hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, end_date, entered_by, status) '||
                            'SELECT DISTINCT '||
                                    l_hlevelid ||' hierarchy_level_id, '||
                                   'stj' || i || '_geo_area_key  geo_area_key, '||
                                   l_typeid || ' geo_polygon_type_id, '||
                                   'NVL(stj' || i || '_startdate, TO_DATE(''01-Jan-2000'')) start_date, '||
                                   'stj' || i || '_enddate end_date, '||
                                   user_i || ' entered_by, '||
                                   l_status || ' status '||
                            'FROM   gis_indata_areas_temp g '||
                            'WHERE  state = ''' || stcode_i || ''' '||
                                   'AND stj' || i || '_geo_area_key IS NOT NULL '||
                                   'AND NOT EXISTS ( SELECT 1 '||
                                                    'FROM   geo_polygons p '||
                                                    'WHERE  p.geo_area_key = g.stj' || i || '_geo_area_key '||
                                                  ')';

                EXECUTE IMMEDIATE l_stmt;
                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;
            END LOOP stj_loop;

            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_polygons', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'create_geo_polygons', paction=>1, puser=>user_i);

            RETURN l_recs;
        END create_geo_polygons;


    -- ************************************************************************************************************ --
    -- Determine End_Date from GIS data                                                                             --
    -- CRAPP-2145                                                                                                   --
    -- If the boundary exists in content repo and the new import does not contain a unique area with that boundary, --
    -- then look for that boundary in the GIS views and pull the end-date from the boundary. If the boundary does   --
    -- not exist in the GIS views, then alert GIS to see if that value should be deleted.                           --
    -- ************************************************************************************************************ --
    PROCEDURE get_polygon_date (stcode_i IN VARCHAR2, user_i IN NUMBER, poly_i IN VARCHAR2, fips_i IN VARCHAR2, type_i IN VARCHAR2, id_i IN NUMBER)
    IS
            l_sql   VARCHAR2(500 CHAR);
            l_rec   NUMBER := 0;
            l_issue VARCHAR2(100 CHAR) := 'Boundary does not exist in GIS feature class with an End Date value';

            TYPE r_polydates IS RECORD
            (
              state_code    VARCHAR2(2 CHAR),
              fips          VARCHAR2(10 CHAR),
              polygon       VARCHAR2(100 CHAR),
              startdate     DATE,
              enddate       DATE
            );

            TYPE t_polydates IS TABLE OF r_polydates;
            v_polydates t_polydates;

        BEGIN

            IF type_i = 'City' THEN

                l_sql := 'SELECT DISTINCT '||
                                 ' '''||stcode_i||''' state_code '||
                                 ', place fips '||
                                 ', placename polygon '||
                                 ', startdate '||
                                 ', enddate '||
                         'FROM   gis.'||stcode_i||'_city_evw@gis.corp.ositax.com '||
                         'WHERE  place = '''||fips_i||''' '||
                                'AND UPPER(placename) = '''||UPPER(poly_i)||''' '||
                                'AND enddate IS NOT NULL';

            ELSE IF type_i = 'STJ' THEN

                l_sql := 'SELECT DISTINCT '||
                                 ' '''||stcode_i||''' state_code '||
                                 ', id fips '||
                                 ', name polygon '||
                                 ', startdate '||
                                 ', enddate '||
                         'FROM   gis.'||stcode_i||'_stj_evw@gis.corp.ositax.com '||
                         'WHERE  id = '''||fips_i||''' '||
                                'AND UPPER(name) = '''||UPPER(poly_i)||''' '||
                                'AND CR = ''Y'' '||
                                'AND enddate IS NOT NULL';
                END IF;
            END IF;

            dbms_output.put_line('Fips: '||fips_i||' Name: '||poly_i);
            dbms_output.put_line(l_sql);

            EXECUTE IMMEDIATE l_sql
            BULK COLLECT INTO v_polydates;

            l_rec := v_polydates.COUNT;
            dbms_output.put_line('l_rec: '||l_rec);

            IF l_rec > 0 THEN
                -- Update polygon End_Date --
                FORALL i IN 1..v_polydates.COUNT
                    UPDATE geo_polygons
                        SET end_date = v_polydates(i).enddate
                    WHERE id = id_i;
            ELSE
                -- Log that the boundary does not exist in GIS data --
                UPDATE geo_poly_issue_log
                    SET entered_date = SYSDATE,
                        entered_by   = user_i
                WHERE     state_code     = stcode_i
                      AND geo_polygon_id = id_i
                      AND geo_area_key   = (stcode_i||'-'||fips_i||'-'||poly_i)
                      AND issue          = l_issue
                      AND action IS NULL;

                l_rec := (SQL%ROWCOUNT);

                IF l_rec = 0 THEN
                    INSERT INTO geo_poly_issue_log
                        (state_code, geo_area_key, geo_polygon_id, rid, nkid, entered_by, issue)
                        SELECT   TRIM(stcode_i) st
                               , (stcode_i||'-'||fips_i||'-'||poly_i) geoareakey
                               , id_i  poly_id
                               , (SELECT rid FROM geo_polygons WHERE id = id_i)   rid
                               , (SELECT nkid FROM geo_polygons WHERE id = id_i)  nkid
                               , user_i  userid
                               , l_issue
                        FROM  dual
                        WHERE NOT EXISTS (
                                          SELECT 1
                                          FROM   geo_poly_issue_log
                                          WHERE      state_code     = stcode_i
                                                 AND geo_polygon_id = id_i
                                                 AND action IS NULL
                                         );

                    l_rec := (SQL%ROWCOUNT);
                    dbms_output.put_line('Inserted: '||l_rec);
                END IF;
            END IF;
            COMMIT;

            v_polydates := t_polydates();
        END get_polygon_date;


    -- *************************************************************** --
    -- Update GEO Polygons changed since last import from GIS database --
    -- *************************************************************** --
    FUNCTION update_geo_polygons (stcode_i IN VARCHAR2, stname_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) RETURN NUMBER -- 10/18/17 - crapp-3600
    IS
            l_sql       VARCHAR2(2000 CHAR);
            l_status    NUMBER := 0;
            l_recs      NUMBER := 0;
            l_ccnt      NUMBER := 0;
            l_pol_pk    NUMBER := 0;
            l_typeid    NUMBER;
            l_suptypeid NUMBER; -- crapp-3600, added
            l_hlevelid  NUMBER;

            TYPE t_polyzip IS TABLE OF gis_poly_zip_temp%ROWTYPE;
            v_polyzip  t_polyzip;


            -- New/Updated County Boundaries -- crapp-2533
            CURSOR county_changes IS
                SELECT  c.*
                       , p.end_date orig_enddate
                       , p.nkid
                FROM   (
                        SELECT  DISTINCT
                                state
                                , county_fips
                                , county_name
                                , TO_DATE('01-Jan-2000') county_startdate
                                , county_geo_area_key
                        FROM    gis_indata_areas_temp
                        WHERE   county_geo_area_key IS NOT NULL
                        MINUS
                        SELECT  DISTINCT
                                SUBSTR(geo_area_key, 1, 2) state
                                , SUBSTR(geo_area_key, 4, 3) county_fips
                                , SUBSTR(geo_area_key, 8) county_name
                                , start_date
                                , geo_area_key
                        FROM    vgeo_polygons
                        WHERE   geo_area = 'County'
                                AND virtual IS NULL     -- crapp-2152
                                AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                       ) c
                       LEFT JOIN geo_polygons p ON (c.county_geo_area_key = p.geo_area_key
                                                    AND p.next_rid IS NULL);

            -- New/Updated Supplemental County Boundaries --
            CURSOR sup_county_changes IS
                SELECT  c.*
                       , p.end_date orig_enddate
                       , p.nkid
                FROM   (
                        SELECT  DISTINCT
                                state
                                , county_fips
                                , county_name
                                , TO_DATE('01-Jan-2000') county_startdate
                                , county_geo_area_key
                        FROM    gis_indata_areas_sup_temp
                        WHERE   county_geo_area_key IS NOT NULL
                        MINUS
                        SELECT  DISTINCT
                                SUBSTR(geo_area_key, 1, 2) state
                                , SUBSTR(geo_area_key, 4, 3) county_fips
                                , SUBSTR(geo_area_key, 8) county_name
                                , start_date
                                , geo_area_key
                        FROM    vgeo_polygons
                        WHERE   geo_area = 'County'
                                AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                       ) c
                       LEFT JOIN geo_polygons p ON (c.county_geo_area_key = p.geo_area_key
                                                    AND p.next_rid IS NULL);

            -- City Boundaries that are now virtual but were once drawn by GIS -- crapp-3560
            CURSOR city_virtual_changes IS
                SELECT c.*
                       , p.id
                       , p.nkid
                FROM   (
                        SELECT  DISTINCT
                                SUBSTR(geo_area_key, 1, 2) state
                                , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN '99999'
                                       ELSE SUBSTR(geo_area_key, 4, 5)
                                  END city_fips
                                , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN 'UNINCORPORATED'
                                       ELSE SUBSTR(geo_area_key, 10)
                                  END city_name
                                , start_date
                                , end_date
                                , geo_area_key
                        FROM    vgeo_polygons
                        WHERE   geo_area = 'City'
                                AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                                AND virtual IS NULL
                        MINUS
                        SELECT  DISTINCT
                                state
                                , city_fips
                                , city_name
                                , NVL(city_startdate, TO_DATE('01-Jan-2000')) start_date
                                , city_enddate      end_date
                                , city_geo_area_key geo_area_key
                        FROM    gis_indata_areas_temp
                        WHERE   city_geo_area_key IS NOT NULL
                       ) c
                       JOIN (SELECT DISTINCT city_geo_area_key
                             FROM   gis_indata_areas_sup_temp
                             WHERE  city_geo_area_key IS NOT NULL
                            ) g ON (c.geo_area_key = g.city_geo_area_key)
                       LEFT JOIN geo_polygons p ON (c.geo_area_key = p.geo_area_key
                                                    AND p.next_rid IS NULL);

            -- City Boundaries Removed --
            CURSOR cities_removed IS
                SELECT r.*, p.id
                FROM   geo_polygons p
                       JOIN (
                            SELECT  DISTINCT
                                    SUBSTR(geo_area_key, 1, 2) state
                                    , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN '99999'           -- now using UPPER Case, crapp-2532
                                           ELSE SUBSTR(geo_area_key, 4, 5)
                                      END city_fips
                                    , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN 'UNINCORPORATED'  -- now using UPPER Case, crapp-2532
                                           ELSE SUBSTR(geo_area_key, 10)
                                      END city_name
                                    , start_date
                                    , end_date
                                    , geo_area_key
                            FROM    vgeo_polygons
                            WHERE   geo_area = 'City'
                                    AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                                    AND end_date IS NULL
                                    AND virtual IS NULL     -- crapp-2152
                            MINUS
                            SELECT  DISTINCT
                                    state
                                    , city_fips
                                    , city_name
                                    , NVL(city_startdate, TO_DATE('01-Jan-2000')) city_startdate
                                    , city_enddate
                                    , city_geo_area_key
                            FROM    gis_indata_areas_temp
                            WHERE   city_geo_area_key IS NOT NULL
                            ) r ON (r.geo_area_key = p.geo_area_key
                                    AND p.next_rid IS NULL)
                WHERE p.geo_area_key NOT IN (SELECT DISTINCT city_geo_area_key FROM gis_indata_areas_sup_temp); -- check to make sure City is not in Supplemental table -- crapp-3560

            -- Supplemental City Boundaries Removed --
            CURSOR sup_cities_removed IS
                SELECT r.*, p.id
                FROM   geo_polygons p
                       JOIN (
                            SELECT  DISTINCT
                                    SUBSTR(geo_area_key, 1, 2) state
                                    , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN '99999'           -- now using UPPER Case, crapp-2532
                                           ELSE SUBSTR(geo_area_key, 4, 5)
                                      END city_fips
                                    , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN 'UNINCORPORATED'  -- now using UPPER Case, crapp-2532
                                           ELSE SUBSTR(geo_area_key, 10)
                                      END city_name
                                    , start_date
                                    , end_date
                                    , geo_area_key
                            FROM    vgeo_polygons
                            WHERE   geo_area = 'City'
                                    AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                                    AND end_date IS NULL
                            MINUS
                                (
                                    SELECT  DISTINCT
                                            state
                                            , city_fips
                                            , city_name
                                            , NVL(city_startdate, TO_DATE('01-Jan-2000')) city_startdate
                                            , city_enddate
                                            , city_geo_area_key
                                    FROM    gis_indata_areas_sup_temp
                                    WHERE   city_geo_area_key IS NOT NULL
                                    UNION
                                    SELECT  DISTINCT
                                            state
                                            , city_fips
                                            , city_name
                                            , NVL(city_startdate, TO_DATE('01-Jan-2000')) city_startdate
                                            , city_enddate
                                            , city_geo_area_key
                                    FROM    gis_indata_areas_temp
                                    WHERE   city_geo_area_key IS NOT NULL
                                )
                            ) r ON (r.geo_area_key = p.geo_area_key
                                    AND p.next_rid IS NULL);

            -- City Boundaries that are now drawn by GIS - no longer virtual -- crapp-3560
            CURSOR sup_city_virtual_changes IS
                SELECT c.*
                       , p.id
                       , p.nkid
                FROM   (
                        SELECT  DISTINCT
                                SUBSTR(geo_area_key, 1, 2) state
                                , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN '99999'
                                       ELSE SUBSTR(geo_area_key, 4, 5)
                                  END city_fips
                                , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN 'UNINCORPORATED'
                                       ELSE SUBSTR(geo_area_key, 10)
                                  END city_name
                                , start_date
                                , end_date
                                , geo_area_key
                        FROM    vgeo_polygons
                        WHERE   geo_area = 'City'
                                AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                                AND virtual = 1
                        MINUS
                        SELECT  DISTINCT
                                state
                                , city_fips
                                , city_name
                                , NVL(city_startdate, TO_DATE('01-Jan-2000')) start_date
                                , city_enddate      end_date
                                , city_geo_area_key geo_area_key
                        FROM    gis_indata_areas_sup_temp
                        WHERE   city_geo_area_key IS NOT NULL
                       ) c
                       JOIN (SELECT DISTINCT city_geo_area_key
                             FROM   gis_indata_areas_temp
                             WHERE  city_geo_area_key IS NOT NULL
                            ) g ON (c.geo_area_key = g.city_geo_area_key)
                       LEFT JOIN geo_polygons p ON (c.geo_area_key = p.geo_area_key
                                                    AND p.next_rid IS NULL);

            -- New City Boundaries --
            CURSOR city_changes IS
                SELECT  DISTINCT
                        state
                        , city_fips
                        , city_name
                        , NVL(city_startdate, TO_DATE('01-Jan-2000')) city_startdate
                        , city_enddate
                        , city_geo_area_key
                FROM    gis_indata_areas_temp
                WHERE   city_geo_area_key IS NOT NULL
                MINUS
                SELECT  DISTINCT
                        SUBSTR(geo_area_key, 1, 2) state
                        , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN '99999'           -- now using UPPER Case, crapp-2532
                               ELSE SUBSTR(geo_area_key, 4, 5)
                          END city_fips
                        , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN 'UNINCORPORATED'  -- now using UPPER Case, crapp-2532
                               ELSE SUBSTR(geo_area_key, 10)
                          END city_name
                        , start_date
                        , end_date
                        , geo_area_key
                FROM    vgeo_polygons
                WHERE   geo_area = 'City'
                        AND virtual IS NULL     -- crapp-2152
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i;

            -- New/Updated Virtual Supplemental City Boundaries --
            CURSOR sup_city_changes IS
                SELECT c.*
                       , p.end_date orig_enddate    -- crapp-2531
                       , p.nkid
                FROM   (
                        SELECT  DISTINCT
                                state
                                , city_fips
                                , city_name
                                , NVL(city_startdate, TO_DATE('01-Jan-2000')) start_date
                                , city_enddate      end_date
                                , city_geo_area_key geo_area_key
                        FROM    gis_indata_areas_sup_temp
                        WHERE   city_geo_area_key IS NOT NULL
                        MINUS
                        SELECT  DISTINCT
                                SUBSTR(geo_area_key, 1, 2) state
                                , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN '99999'           -- now using UPPER Case, crapp-2532
                                       ELSE SUBSTR(geo_area_key, 4, 5)
                                  END city_fips
                                , CASE WHEN geo_area_key LIKE '%UNINCORPORATED%' THEN 'UNINCORPORATED'  -- now using UPPER Case, crapp-2532
                                       ELSE SUBSTR(geo_area_key, 10)
                                  END city_name
                                , start_date
                                , end_date
                                , geo_area_key
                        FROM    vgeo_polygons
                        WHERE   geo_area = 'City'
                                AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                       ) c
                       LEFT JOIN geo_polygons p ON (c.geo_area_key = p.geo_area_key
                                                    AND p.next_rid IS NULL);

            -- STJ Boundaries Changes --
            CURSOR stj_changes IS
                SELECT  DISTINCT
                        state
                        , stj_fips
                        , stj_name
                        , city_startdate stj_startdate
                        , stj_enddate
                        , geo_area_key
                FROM    gis_poly_zip_temp
                MINUS
                SELECT  DISTINCT
                        SUBSTR(geo_area_key, 1, 2) state
                        , SUBSTR(geo_area_key, 4, INSTR(geo_area_key, '-', 4)-4) stj_fips
                        , SUBSTR(geo_area_key, INSTR(geo_area_key, '-', 4)+1)    stj_name
                        , start_date
                        , end_date
                        , geo_area_key
                FROM    vgeo_polygons
                WHERE   geo_area = 'District'
                        AND virtual IS NULL     -- crapp-2152
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i;

            -- Supplemental STJ Boundaries Changes --
            CURSOR sup_stj_changes IS
                SELECT  DISTINCT
                        state
                        , stj_fips
                        , stj_name
                        , city_startdate stj_startdate
                        , stj_enddate
                        , geo_area_key
                FROM    gis_poly_zip_temp
                WHERE   stj_fips IS NOT NULL
                MINUS
                SELECT  DISTINCT
                        SUBSTR(geo_area_key, 1, 2) state
                        , SUBSTR(geo_area_key, 4, INSTR(geo_area_key, '-', 4)-4) stj_fips
                        , SUBSTR(geo_area_key, INSTR(geo_area_key, '-', 4)+1)    stj_name
                        , start_date
                        , end_date
                        , geo_area_key
                FROM    vgeo_polygons
                WHERE   geo_area = 'District'
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i;

            -- STJ Boundaries Removed --
            CURSOR stjs_removed IS
                SELECT r.*, p.id
                FROM   geo_polygons p
                       JOIN (
                            SELECT  DISTINCT
                                    SUBSTR(geo_area_key, 1, 2) state
                                    , SUBSTR(geo_area_key, 4, INSTR(geo_area_key, '-', 4)-4) stj_fips
                                    , SUBSTR(geo_area_key, INSTR(geo_area_key, '-', 4)+1)    stj_name
                                    , start_date
                                    , end_date
                                    , geo_area_key
                            FROM    vgeo_polygons
                            WHERE   geo_area = 'District'
                                    AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                                    AND end_date IS NULL
                                    AND virtual IS NULL     -- crapp-2152
                            MINUS
                            SELECT  DISTINCT
                                    state
                                    , stj_fips
                                    , stj_name
                                    , city_startdate stj_startdate
                                    , stj_enddate
                                    , geo_area_key
                            FROM    gis_poly_zip_temp
                            ) r ON (r.geo_area_key = p.geo_area_key
                                    AND p.next_rid IS NULL);

            -- Supplemental STJ Boundaries Removed --
            CURSOR sup_stjs_removed IS
                SELECT r.*, p.id
                FROM   geo_polygons p
                       JOIN (
                            SELECT  DISTINCT
                                    SUBSTR(geo_area_key, 1, 2) state
                                    , SUBSTR(geo_area_key, 4, INSTR(geo_area_key, '-', 4)-4) stj_fips
                                    , SUBSTR(geo_area_key, INSTR(geo_area_key, '-', 4)+1)    stj_name
                                    , start_date
                                    , end_date
                                    , geo_area_key
                            FROM    vgeo_polygons
                            WHERE   geo_area = 'District'
                                    AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                                    AND end_date IS NULL
                                    AND virtual = 1         -- crapp-2425, added
                            MINUS
                            SELECT  DISTINCT
                                    state
                                    , stj_fips
                                    , stj_name
                                    , city_startdate stj_startdate
                                    , stj_enddate
                                    , geo_area_key
                            FROM    gis_poly_zip_temp
                            WHERE   stj_fips IS NOT NULL
                            ) r ON (r.geo_area_key = p.geo_area_key
                                    AND p.next_rid IS NULL);

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_geo_polygons', paction=>0, puser=>user_i);

            -- Make sure all indexes used are valid --
            SELECT COUNT(1)
            INTO   l_recs
            FROM   all_indexes
            WHERE  owner = 'CONTENT_REPO'
                   AND index_name IN ('GEO_POLYGONS_N1', 'GEO_POLYGONS_N2', 'GEO_POLYGONS_N3', 'GEO_POLYGONS_PK', 'GEO_POLYGONS_UN')
                   AND status = 'UNUSABLE';

            IF l_recs > 0 THEN
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes, - geo_polygons', paction=>0, puser=>user_i);
                EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_n1 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_n2 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_n3 REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_pk REBUILD';
                EXECUTE IMMEDIATE 'ALTER INDEX geo_polygons_un REBUILD';
                l_recs := 0;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes, - geo_polygons', paction=>1, puser=>user_i);
            END IF;

            SELECT id
            INTO   l_typeid
            FROM   geo_polygon_types
            WHERE  NAME = 'STANDARD';       -- crapp-3600, changed to STANDARD from JURISDICTION

            SELECT id
            INTO   l_suptypeid
            FROM   geo_polygon_types
            WHERE  NAME = 'SUPPLEMENTAL';   -- crapp-3600, added

            -- ****************** --
            -- Update County Data --
            -- ****************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update County level boundaries, - geo_polygons', paction=>0, puser=>user_i);

            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'County';

            -- Name change only --
            FOR c IN county_changes LOOP
                UPDATE geo_polygons p
                    SET geo_area_key = c.county_geo_area_key,
                        start_date   = c.county_startdate,
                        entered_by   = user_i
                WHERE SUBSTR(p.geo_area_key, 1, 2) = c.state
                      AND SUBSTR(p.geo_area_key, 1, 6) = (c.state||'-'||c.county_fips)
                      AND p.geo_area_key <> c.county_geo_area_key
                      AND p.hierarchy_level_id = l_hlevelid
                RETURNING id INTO l_pol_pk;

                IF l_pol_pk <> 0 THEN
                    l_recs := l_recs + 1;
                    l_pol_pk := 0;
                    dbms_output.put_line('Updated county boundary: '||c.county_geo_area_key);
                END IF;
                COMMIT;
            END LOOP;

            -- Supplemental Name change only --
            FOR c IN sup_county_changes LOOP
                UPDATE geo_polygons p
                    SET geo_area_key = c.county_geo_area_key,
                        start_date   = c.county_startdate,
                        entered_by   = user_i
                WHERE SUBSTR(p.geo_area_key, 1, 2) = c.state
                      AND SUBSTR(p.geo_area_key, 1, 6) = (c.state||'-'||c.county_fips)
                      AND p.geo_area_key <> c.county_geo_area_key
                      AND p.hierarchy_level_id = l_hlevelid
                RETURNING id INTO l_pol_pk;

                IF l_pol_pk <> 0 THEN
                    l_recs := l_recs + 1;
                    l_pol_pk := 0;
                    dbms_output.put_line('Updated supplemental county boundary: '||c.county_geo_area_key);
                END IF;
                COMMIT;
            END LOOP;

            -- New County Boundary --
            FOR c IN county_changes LOOP
                INSERT INTO geo_polygons
                    (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status)
                    SELECT  l_hlevelid
                            , c.county_geo_area_key
                            , l_typeid
                            , c.county_startdate
                            , user_i
                            , l_status
                    FROM    dual d
                    WHERE NOT EXISTS ( SELECT 1
                                       FROM   geo_polygons p
                                       WHERE  SUBSTR(p.geo_area_key, 1, 2) = c.state
                                              AND p.geo_area_key = c.county_geo_area_key
                                              AND SUBSTR(p.geo_area_key, 1, 6) = (c.state||'-'||c.county_fips) -- check County Fips value
                                     );

                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;

                dbms_output.put_line('Added new county boundary: '||c.county_geo_area_key);
            END LOOP;

            -- New Supplemental County Boundary --
            FOR c IN sup_county_changes LOOP
                INSERT INTO geo_polygons
                    (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status, virtual)
                    SELECT  l_hlevelid
                            , c.county_geo_area_key
                            , l_suptypeid           -- crapp-3600
                            , c.county_startdate
                            , user_i
                            , l_status
                            , 1
                    FROM    dual d
                    WHERE NOT EXISTS ( SELECT 1
                                       FROM   geo_polygons p
                                       WHERE  SUBSTR(p.geo_area_key, 1, 2) = c.state
                                              AND p.geo_area_key = c.county_geo_area_key
                                              AND SUBSTR(p.geo_area_key, 1, 6) = (c.state||'-'||c.county_fips) -- check County Fips value
                                     );

                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;

                dbms_output.put_line('Added new supplemental county boundary: '||c.county_geo_area_key);
            END LOOP;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update County level boundaries, - geo_polygons', paction=>1, puser=>user_i);


            -- **************** --
            -- Update City Data --
            -- **************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update City level boundaries, - geo_polygons', paction=>0, puser=>user_i);
            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'City';

            -- City Name changes -- crapp-3152, moved to before removals
            FOR c IN city_changes LOOP
                UPDATE geo_polygons p
                    SET geo_area_key = c.city_geo_area_key,
                        start_date   = c.city_startdate,
                        entered_by   = user_i
                WHERE SUBSTR(p.geo_area_key, 1, 2) = c.state
                      AND SUBSTR(p.geo_area_key, 1, 8) = (c.state||'-'||c.city_fips)
                      AND p.geo_area_key <> c.city_geo_area_key
                      AND p.hierarchy_level_id = l_hlevelid
                RETURNING id INTO l_pol_pk;

                IF l_pol_pk <> 0 THEN
                    l_recs := l_recs + 1;
                    l_pol_pk := 0;
                    dbms_output.put_line('Updated: '||c.city_geo_area_key);
                END IF;
                COMMIT;
            END LOOP;

            -- Supplemental City Name changes --
            FOR c IN sup_city_changes LOOP
                UPDATE geo_polygons p
                    SET geo_area_key = c.geo_area_key,
                        start_date   = c.start_date,
                        entered_by   = user_i
                WHERE SUBSTR(p.geo_area_key, 1, 2) = c.state
                      AND SUBSTR(p.geo_area_key, 1, 8) = (c.state||'-'||c.city_fips)
                      AND p.geo_area_key <> c.geo_area_key
                      AND p.hierarchy_level_id = l_hlevelid
                RETURNING id INTO l_pol_pk;

                IF l_pol_pk <> 0 THEN
                    l_recs := l_recs + (SQL%ROWCOUNT);
                    l_pol_pk := 0;
                    dbms_output.put_line('Updated supplemental boundary: '||c.geo_area_key);
                END IF;
                COMMIT;
            END LOOP;


            -- City boundaries that are virtual but were once drawn in AcrMap -- crapp-3560
            FOR c IN city_virtual_changes LOOP
                UPDATE geo_polygons
                    SET virtual = 1,
                        geo_polygon_type_id = l_suptypeid   -- crapp-3600
                WHERE id = c.id;

                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;
            END LOOP;

            -- City boundaries that have been removed in GIS --
            FOR c IN cities_removed LOOP
                -- Determine END_DATE and update, otherwise log Issue -- crapp-2145
                load_gis.get_polygon_date(stcode_i=> c.state, user_i=> user_i, poly_i=> c.city_name, fips_i=> c.city_fips, type_i=> 'City', id_i=> c.id);

                l_recs := l_recs + 1;
                COMMIT;
            END LOOP;


            -- Supplemental City boundaries that are no longer Virtual and are now drawn in AcrMap -- crapp-3560
            FOR c IN sup_city_virtual_changes LOOP
                UPDATE geo_polygons
                    SET virtual = NULL,
                        end_date = NULL,
                        geo_polygon_type_id = l_typeid  -- crapp-3600
                WHERE id = c.id;

                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;
            END LOOP;

            -- Supplemental City boundaries that have been removed in GIS --
            FOR c IN sup_cities_removed LOOP
                -- Since these are Virtual City Polygons, they will not have an END_DATE in the GIS data --
                UPDATE geo_polygons
                    SET end_date = TRUNC(SYSDATE)
                WHERE id = c.id
                      AND geo_area_key = c.geo_area_key;

                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;
            END LOOP;


            -- New City Boundaries --
            FOR c IN city_changes LOOP <<city_change_loop>>
                INSERT INTO geo_polygons
                    (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status)
                    SELECT  l_hlevelid
                            , c.city_geo_area_key
                            , l_typeid
                            , c.city_startdate
                            , user_i
                            , l_status
                    FROM    dual d
                    WHERE NOT EXISTS ( SELECT 1
                                       FROM   geo_polygons p
                                       WHERE  SUBSTR(p.geo_area_key, 1, 2) = c.state
                                              AND p.geo_area_key = c.city_geo_area_key
                                              AND SUBSTR(p.geo_area_key, 1, 8) = (c.state||'-'||c.city_fips) -- check City Fips value
                                     );
                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;
            END LOOP city_change_loop;

            -- New Supplemental City Boundaries --
            FOR c IN sup_city_changes LOOP

                -- City boundaries that have been reactivated in GIS --   crapp-2531
                IF c.end_date IS NULL AND c.orig_enddate IS NOT NULL THEN
                    UPDATE geo_polygons
                        SET start_date = c.start_date,
                            end_date   = NULL,
                            entered_by = user_i
                    WHERE geo_area_key = c.geo_area_key
                          AND end_date IS NOT NULL
                          AND next_rid IS NULL;

                    l_recs := l_recs + (SQL%ROWCOUNT);
                    dbms_output.put_line(CHR(10)||'Reset EndDate of supplemental city boundary: '||c.geo_area_key);
                END IF;

                -- New Boundaries --
                IF c.nkid IS NULL THEN
                    INSERT INTO geo_polygons
                        (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, entered_by, status, virtual)
                        SELECT  l_hlevelid
                                , c.geo_area_key
                                , l_suptypeid       -- crapp-3600
                                , c.start_date
                                , user_i
                                , l_status
                                , 1
                        FROM    dual d
                        WHERE NOT EXISTS ( SELECT 1
                                           FROM   geo_polygons p
                                           WHERE  SUBSTR(p.geo_area_key, 1, 2) = c.state
                                                  AND p.geo_area_key = c.geo_area_key
                                                  AND SUBSTR(p.geo_area_key, 1, 8)  = (c.state||'-'||c.city_fips) -- check City Fips value
                                         );

                    l_recs := l_recs + (SQL%ROWCOUNT);
                    dbms_output.put_line('Added new supplemental city boundary: '||c.geo_area_key);
                END IF;
            END LOOP;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update City level boundaries, - geo_polygons', paction=>1, puser=>user_i);


            -- *************** --
            -- Update STJ Data --
            -- *************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update District level boundaries, - geo_polygons', paction=>0, puser=>user_i);

            SELECT  hl.id
            INTO    l_hlevelid
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'District';

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            FOR i IN 1..9 LOOP
                l_sql := 'SELECT  /*+index(t gis_indata_areas_temp_g4)*/ '||
                                  'DISTINCT '||
                                  'stj' || i || '_geo_area_key  geo_area_key '||
                                  ', state_name '||
                                  ', state '||
                                  ', NULL state_fips '||
                                  ', NULL county_name '||
                                  ', NULL county_fips '||
                                  ', NULL city_name '||
                                  ', NULL city_fips '||
                                  ', NVL(stj' || i || '_startdate, TO_DATE(''01-Jan-2000'')) city_startdate '||
                                  ', NULL city_enddate '||
                                  ', stj' || i || '_name stj_name '||
                                  ', stj' || i || '_id   stj_fips '||
                                  ', stj' || i || '_enddate stj_enddate '||
                                  ', NULL zip9 '||
                                  ', NULL zip '||
                                  ', NULL zip4 '||
                                  ', NULL default_zip4 '||
                                  ', NULL city_rank '||
                                  ', NULL geo_poly_id '||
                                  ', area_id '||
                          'FROM    gis_indata_areas_temp t '||
                          'WHERE   stj' || i || '_geo_area_key IS NOT NULL ';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_polyzip;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;

                v_polyzip := t_polyzip();
            END LOOP;
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);

            -- STJ boundaries that have been reactivated in GIS --
            FOR s IN stj_changes LOOP
                IF s.stj_enddate IS NULL THEN
                    UPDATE geo_polygons
                        SET start_date = s.stj_startdate,
                            end_date   = NULL,
                            entered_by = user_i
                    WHERE geo_area_key = s.geo_area_key
                          AND end_date IS NOT NULL
                          AND next_rid IS NULL;

                    l_recs := l_recs + (SQL%ROWCOUNT);
                END IF;
            END LOOP;
            COMMIT;

            -- STJ boundaries - Update Start Date --  crapp-2048
            FOR s IN stj_changes LOOP
                --IF s.stj_enddate IS NULL THEN                 -- crapp-2145 removed, want to check all start date values
                    UPDATE geo_polygons
                        SET start_date = s.stj_startdate,
                            entered_by = user_i
                    WHERE geo_area_key = s.geo_area_key
                          --AND end_date IS NULL                -- crapp-2145 removed, want to check all start date values
                          AND NVL(start_date, TO_DATE('01-Jan-1900')) <> s.stj_startdate     -- crapp-2145 added
                          AND next_rid IS NULL;

                    l_recs := l_recs + (SQL%ROWCOUNT);
                --END IF;
            END LOOP;
            COMMIT;


            -- STJ Name change only --
            FOR s IN stj_changes LOOP
                UPDATE geo_polygons p
                    SET geo_area_key = s.geo_area_key,
                        start_date   = s.stj_startdate,     -- crapp-2145, added just in case value is different
                        end_date     = s.stj_enddate,       -- crapp-2145, added just in case value is different
                        entered_by   = user_i
                WHERE SUBSTR(p.geo_area_key, 1, 2) = s.state
                      AND SUBSTR(p.geo_area_key, 1, 9) = (s.state||'-'||s.stj_fips)
                      AND p.geo_area_key <> s.geo_area_key;

                l_recs := l_recs + (SQL%ROWCOUNT);
            END LOOP;
            COMMIT;


            -- New STJ boundaries --
            FOR s IN stj_changes LOOP
                INSERT INTO geo_polygons
                    (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, end_date, entered_by, status)
                    SELECT  l_hlevelid
                            , s.geo_area_key
                            , l_typeid
                            , s.stj_startdate
                            , s.stj_enddate
                            , user_i
                            , l_status
                    FROM    dual d
                    WHERE NOT EXISTS ( SELECT 1
                                       FROM   geo_polygons p
                                       WHERE  SUBSTR(p.geo_area_key, 1, 2) = s.state
                                              AND p.geo_area_key = s.geo_area_key
                                              AND SUBSTR(p.geo_area_key, 1, 9) = (s.state||'-'||s.stj_fips) -- check STJ Fips value
                                     );

                l_recs := l_recs + (SQL%ROWCOUNT);
            END LOOP;
            COMMIT;


            -- STJ boundaries - Update End Date for STJs in GIS import data --  crapp-2145
            FOR s IN stj_changes LOOP
                IF s.stj_enddate IS NOT NULL THEN
                    UPDATE geo_polygons
                        SET end_date = s.stj_enddate,
                            entered_by = user_i
                    WHERE geo_area_key = s.geo_area_key
                          AND NVL(end_date, TO_DATE('01-Jan-1900')) <> s.stj_enddate
                          AND next_rid IS NULL;

                    l_recs := l_recs + (SQL%ROWCOUNT);
                END IF;
            END LOOP;
            COMMIT;


            -- STJ boundaries that have been removed in GIS --
            FOR s IN stjs_removed LOOP
                -- Determine END_DATE and update, otherwise log Issue -- crapp-2145
                load_gis.get_polygon_date(stcode_i=> s.state, user_i=> user_i, poly_i=> s.stj_name, fips_i=> s.stj_fips, type_i=> 'STJ', id_i=> s.id);

                l_recs := l_recs + 1;
            END LOOP;
            COMMIT;

            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_polygons', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update District level boundaries, - geo_polygons', paction=>1, puser=>user_i);


            -- ************************************* --
            -- Update Supplemental STJ Boundary Data --
            -- ************************************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update District level boundaries, supplemental_uas data - geo_polygons', paction=>0, puser=>user_i);

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            FOR i IN 1..9 LOOP
                l_sql := 'SELECT  /*+index(t gis_indata_areas_sup_temp_g4)*/ '||
                                  'DISTINCT '||
                                  'stj' || i || '_geo_area_key  geo_area_key '||
                                  ', state_name '||
                                  ', state '||
                                  ', NULL state_fips '||
                                  ', NULL county_name '||
                                  ', NULL county_fips '||
                                  ', NULL city_name '||
                                  ', NULL city_fips '||
                                  ', NVL(stj' || i || '_startdate, TO_DATE(''01-Jan-2000'')) city_startdate '||
                                  ', NULL city_enddate '||
                                  ', stj' || i || '_name stj_name '||
                                  ', stj' || i || '_id   stj_fips '||
                                  ', stj' || i || '_enddate stj_enddate '||
                                  ', NULL zip9 '||
                                  ', NULL zip '||
                                  ', NULL zip4 '||
                                  ', NULL default_zip4 '||
                                  ', NULL city_rank '||
                                  ', NULL geo_poly_id '||
                                  ', area_id '||
                          'FROM    gis_indata_areas_sup_temp t '||
                          'WHERE   stj' || i || '_geo_area_key IS NOT NULL ';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_polyzip;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;

                v_polyzip := t_polyzip();
            END LOOP;
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);

            -- Supplemental STJ boundaries that have been reactivated in GIS --
            FOR s IN sup_stj_changes LOOP
                IF s.stj_enddate IS NULL THEN
                    UPDATE geo_polygons
                        SET start_date = s.stj_startdate,
                            end_date   = NULL,
                            entered_by = user_i
                    WHERE geo_area_key = s.geo_area_key
                          AND end_date IS NOT NULL
                          AND next_rid IS NULL;

                    l_recs := l_recs + (SQL%ROWCOUNT);
                END IF;
            END LOOP;
            COMMIT;

            -- Supplemental STJ boundaries - Update Start Date --  crapp-2048
            FOR s IN sup_stj_changes LOOP
                UPDATE geo_polygons
                    SET start_date = s.stj_startdate,
                        entered_by = user_i
                WHERE geo_area_key = s.geo_area_key
                      AND NVL(start_date, TO_DATE('01-Jan-1900')) <> s.stj_startdate     -- crapp-2145 added
                      AND next_rid IS NULL;

                l_recs := l_recs + (SQL%ROWCOUNT);
            END LOOP;
            COMMIT;

            -- Supplemental STJ Name changes only --
            FOR s IN sup_stj_changes LOOP
                UPDATE geo_polygons p
                    SET geo_area_key = s.geo_area_key,
                        start_date   = s.stj_startdate,
                        end_date     = s.stj_enddate,
                        entered_by   = user_i
                WHERE SUBSTR(p.geo_area_key, 1, 2) = s.state
                      AND SUBSTR(p.geo_area_key, 1, 9) = (s.state||'-'||s.stj_fips)
                      AND p.geo_area_key <> s.geo_area_key;

                l_recs := l_recs + (SQL%ROWCOUNT);
            END LOOP;
            COMMIT;

            -- New Supplemental STJ boundaries --
            FOR s IN sup_stj_changes LOOP
                INSERT INTO geo_polygons
                    (hierarchy_level_id, geo_area_key, geo_polygon_type_id, start_date, end_date, entered_by, status, virtual)
                    SELECT  l_hlevelid
                            , s.geo_area_key
                            , l_suptypeid       -- crapp-3600
                            , s.stj_startdate
                            , s.stj_enddate
                            , user_i
                            , l_status
                            , 1
                    FROM    dual d
                    WHERE NOT EXISTS ( SELECT 1
                                       FROM   geo_polygons p
                                       WHERE  SUBSTR(p.geo_area_key, 1, 2) = s.state
                                              AND p.geo_area_key = s.geo_area_key
                                              AND SUBSTR(p.geo_area_key, 1, 9)  = (s.state||'-'||s.stj_fips) -- check STJ Fips value
                                     );

                l_recs := l_recs + (SQL%ROWCOUNT);
            END LOOP;
            COMMIT;

            -- Supplemental STJ boundaries - Update End Date for STJs in GIS import data --  crapp-2145
            FOR s IN sup_stj_changes LOOP
                IF s.stj_enddate IS NOT NULL THEN
                    UPDATE geo_polygons
                        SET end_date = s.stj_enddate,
                            entered_by = user_i
                    WHERE geo_area_key = s.geo_area_key
                          AND NVL(end_date, TO_DATE('01-Jan-1900')) <> s.stj_enddate
                          AND next_rid IS NULL;

                    l_recs := l_recs + (SQL%ROWCOUNT);
                END IF;
            END LOOP;
            COMMIT;

            -- Supplemental STJ boundaries that have been removed in GIS --
            FOR s IN sup_stjs_removed LOOP
                -- Since these are Virtual STJ boundaries, they will not have an END_DATE in the GIS data --
                UPDATE geo_polygons
                    SET end_date = TRUNC(SYSDATE)
                WHERE id = s.id
                      AND geo_area_key = s.geo_area_key;

                l_recs := l_recs + (SQL%ROWCOUNT);
            END LOOP;
            COMMIT;

            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_polygons', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update District level boundaries, supplemental_uas data - geo_polygons', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_geo_polygons', paction=>1, puser=>user_i);
            RETURN l_recs;
        END update_geo_polygons;



    -- ******************************************************************************************************* --
    -- Set Ranking and Counts in GIS_INDATA_AREAS_TEMP --   -- updated 11/01/17 - crapp-3968                   --
    -- ******************************************************************************************************* --
    -- Default City:                                                                                           --
    -- Choosing the zone of the city that will be marked with the default flag in Determination:               --
    -- 1. The zone of the city with the most individual zip9s within it is the default city/county combination --
    -- 2. If equal, alphabetical by city                                                                       --
    -- 3. If equal, then alphabetical by county (crapp-3485)                                                   --
    --                                                                                                         --
    -- Default Zip Codes (Zip5):                                                                               --
    -- Choosing the zone of the Zip5 that will be marked with the default flag in Determination:               --
    -- 1. The zone of the zip code that has over 60% gets priority rank 1 (even unincorporated)                --
    -- 2. If no zone has more than 60%, then choose the city with the highest count                            --
    -- 3. If two cities are equal, choose alphabetically                                                       --
    -- 4. If the cities are the same, choose alphabetically by county  (crapp-3880)                            --
    --                                                                                                         --
    -- Default Zip+4 (Zip9):                                                                                   --
    -- Choosing which zip9 point makes it into Determination (there is no flag for this, Determination can     --
    --    only support unique zip+4s,but we have non-unique zip+4s in the GIS data)                            --
    -- 1. The chunk with more points is the default                                                            --
    -- 2. If the number of points are equal then we go with the better MATCH                                   --
    -- 3. If that is equal we go with the piece that has a city                                                --
    -- 4. If they both have a city we go with the piece that has a district                                    --
    -- 5. If they both have a district we go with the piece that has the most districts                        --
    -- 6. If they have the same number of STJs we go with alphabetical by City                                 --
    -- 7. If they are in the same city, go alphabetical by STJ                                                 --
    -- ******************************************************************************************************* --
    PROCEDURE update_ranking (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER)
    IS
            l_ccnt NUMBER := 0;

            TYPE t_zipcnt IS TABLE OF gis_zipcount_temp%ROWTYPE;
            v_zipcnt  t_zipcnt;

            TYPE r_citydefault IS RECORD            -- crapp-3880
            (
                state_code    VARCHAR2(2 CHAR)
              , county_name   VARCHAR2(65 CHAR)
              , city_name     VARCHAR2(65 CHAR)
              , default_city  VARCHAR2(1 CHAR)
            );
            TYPE t_citydefault IS TABLE OF r_citydefault;
            v_citydefault t_citydefault;

            TYPE r_zip5default IS RECORD            -- crapp-3880
            (
                state_code    VARCHAR2(2 CHAR)
              , zip           VARCHAR2(5 CHAR)
              , county_name   VARCHAR2(65 CHAR)
              , city_name     VARCHAR2(65 CHAR)
              , countyrank    NUMBER(2,0)
              , zonecityrank  VARCHAR2(2 CHAR)
              , listrank      VARCHAR2(25 CHAR)
              , totalrank     NUMBER(2,0)
              , default_zip   VARCHAR2(1 CHAR)
            );
            TYPE t_zip5default IS TABLE OF r_zip5default;
            v_zip5default t_zip5default;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_ranking', paction=>0, puser=>user_i);

            -- ************************************** --
            -- Remove blank State/County/City records --
            -- ************************************** --
            DELETE
            FROM    gis_indata_areas_temp
            WHERE   state IS NULL
                    AND county_name IS NULL
                    AND city_name IS NULL;

            COMMIT;

            -- ******************* --
            -- Update Default City --
            -- ******************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default City - gis_indata_areas_temp', paction=>0, puser=>user_i);
            WITH cities AS (
                 SELECT  DISTINCT
                         t.state
                         , t.county_name
                         , t.city_name
                         , COUNT( DISTINCT NVL(t.zip9,-1) ) zipcnt
                         , TO_CHAR( SUM( COUNT( DISTINCT NVL(t.zip9,-1) )) OVER( PARTITION BY t.state, t.city_name ), '999999' ) citytotal
                         , TO_CHAR( ratio_to_report( SUM( 1 )) OVER( PARTITION BY t.state, t.city_name ), '0.9999' ) cityratio
                         , RANK( ) OVER( PARTITION BY t.state, t.city_name ORDER BY t.county_name) alphacountyrank    -- crapp-3485
                 FROM    (
                            SELECT state, county_name, city_name, zip9 FROM gis_indata_areas_temp WHERE state = stcode_i
                            UNION
                            SELECT state, county_name, city_name, zip9 FROM gis_indata_areas_sup_temp WHERE state = stcode_i  -- crapp-3485
                         ) t
                         JOIN (
                                SELECT  state
                                        , city_name
                                        , COUNT(DISTINCT county_name) counties
                                FROM    gis_indata_areas_temp
                                WHERE   city_name <> 'UNINCORPORATED'
                                        AND state = stcode_i
                                GROUP BY state
                                        , city_name
                                HAVING COUNT(DISTINCT county_name) > 1     -- crapp-1802
                                UNION  -- crapp-3485 --
                                SELECT  state
                                        , city_name
                                        , COUNT(DISTINCT county_name) counties
                                FROM    gis_indata_areas_sup_temp
                                WHERE   city_name <> 'UNINCORPORATED'
                                        AND state = stcode_i
                                GROUP BY state
                                        , city_name
                                HAVING COUNT(DISTINCT county_name) > 1
                              ) c ON ( t.state = c.state
                                       AND t.city_name = c.city_name)
                 WHERE   t.city_name <> 'UNINCORPORATED'
                         AND t.state = stcode_i
                 GROUP BY  t.state
                         , t.county_name
                         , t.city_name
                )
               , cityrank AS (
                 SELECT state
                        , county_name
                        , city_name
                        , zipcnt
                        , citytotal
                        , cityratio
                        , alphacountyrank
                        , RANK( ) OVER( PARTITION BY state, city_name ORDER BY cityratio DESC ) cityrank
                 FROM   cities c
                )
               , results AS (   -- crapp-3485
                 SELECT state
                        , county_name
                        , city_name
                        , zipcnt
                        , citytotal
                        , cityratio
                        , cityrank
                        , alphacountyrank
                        , listrank
                        , RANK( ) OVER( PARTITION BY state, city_name ORDER BY listrank ) defaultcityrank
                 FROM (
                        SELECT state
                               , county_name
                               , city_name
                               , zipcnt
                               , cityrank
                               , TO_NUMBER(citytotal) citytotal
                               , TO_NUMBER(cityratio, '9D9999' ) cityratio
                               , LPAD(NVL(alphacountyrank, 99),2,0) alphacountyrank
                               , TO_NUMBER(LPAD(NVL(cityrank, 99),2,0)||
                                           LPAD(NVL(alphacountyrank, 99),2,0)
                                          ) listrank
                        FROM   cityrank
                      )
                )
                 SELECT state
                        , county_name
                        , city_name
                        , CASE WHEN defaultcityrank = 1 THEN 'Y' ELSE NULL END default_city
                 BULK COLLECT INTO v_citydefault
                 FROM   results
                 WHERE  defaultcityrank = 1;

            FORALL d IN 1..v_citydefault.COUNT
                UPDATE gis_indata_areas_temp t
                    SET t.default_city = v_citydefault(d).default_city
                WHERE     t.state       = v_citydefault(d).state_code
                      AND t.county_name = v_citydefault(d).county_name
                      AND t.city_name   = v_citydefault(d).city_name;
            COMMIT;

            -- crapp-3485, added --
            FORALL d IN 1..v_citydefault.COUNT
                UPDATE gis_indata_areas_sup_temp t
                    SET t.default_city = v_citydefault(d).default_city
                WHERE     t.state       = v_citydefault(d).state_code
                      AND t.county_name = v_citydefault(d).county_name
                      AND t.city_name   = v_citydefault(d).city_name;
            COMMIT;
            v_citydefault := t_citydefault();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default City - gis_indata_areas_temp', paction=>1, puser=>user_i);


            -- ******************* --
            -- Update Default Zip5 --
            -- ******************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Zip5 - gis_indata_areas_temp', paction=>0, puser=>user_i);
            WITH zones AS
                (
                  SELECT r.state
                         , r.zip
                         , r.county_name
                         , r.city_name
                         , r.zipcnt
                         , TO_NUMBER(r.countytotal) countytotal
                         , TO_NUMBER(r.countyratio, '9D9999' ) countyratio
                         , RANK( ) OVER( PARTITION BY r.state, r.zip ORDER BY r.county_name) alphacountyrank                 -- 09/05/17 - crapp-3880
                         , RANK( ) OVER( PARTITION BY r.state, r.zip, r.county_name ORDER BY r.countyratio DESC ) countyrank
                         , RANK( ) OVER( PARTITION BY r.state, r.zip, r.county_name ORDER BY r.city_name) alphacityrank      -- 04/24/16 - crapp-2541
                         , RANK( ) OVER( PARTITION BY r.state, r.zip ORDER BY r.city_name) overall_alphacityrank             -- 06/29/16 - crapp-2777
                         , RANK( ) OVER( PARTITION BY r.state, r.zip, r.county_name ORDER BY r.zipcnt DESC) zonecityrank     -- 04/24/16 - crapp-2541
                  FROM   ( SELECT  DISTINCT
                                   state
                                   , zip
                                   , county_name
                                   , city_name
                                   , COUNT( code_fips ) zipcnt
                                   , TO_CHAR( SUM( COUNT( code_fips )) OVER( PARTITION BY state, zip ), '999999' )   countytotal
                                   , TO_CHAR( ratio_to_report( SUM( 1 )) OVER( PARTITION BY state, zip ), '0.9999' ) countyratio
                           FROM    ( SELECT DISTINCT
                                            state
                                            , zip
                                            , county_name
                                            , city_name
                                            , (state_fips||county_fips||city_fips||zip||zip4) code_fips
                                     FROM   gis_indata_areas_temp
                                     WHERE  state = stcode_i
                                            AND zip IS NOT NULL
                                   ) z
                           GROUP BY zip
                                    , state
                                    , county_name
                                    , city_name
                         ) r
                  ORDER BY r.zip
                           , r.state
                           , r.county_name
                           , r.city_name
                )
                , gtsixty AS ( -- The zone of the zip code that has over 60% gets priority rank 1 (even unincorporated)
                   SELECT state
                          , zip
                          , county_name
                          , city_name
                          , zipcnt
                          , RANK( ) OVER( PARTITION BY state, zip ORDER BY countyratio DESC ) gtrank
                   FROM   zones
                   WHERE  countyratio >= 0.6
                )
                , cities AS ( -- If no zone has more than 60%, then choose the city with the highest count
                   SELECT state
                          , zip
                          , county_name
                          , city_name
                          , zipcnt
                          , RANK( ) OVER( PARTITION BY state, zip ORDER BY zipcnt DESC) cityrank
                   FROM   zones c
                   WHERE  UPPER( NVL(city_name, 'UNINCORPORATED') ) <> 'UNINCORPORATED' -- now using UPPER Case, crapp-2532
                          AND NOT EXISTS ( SELECT 1
                                           FROM   gtsixty g
                                           WHERE  g.state = c.state
                                                  AND g.zip = c.zip
                                         )
                )
                , other AS (  -- If not more than 60% and city is not in CITIES results, rank by County
                   SELECT state
                            , zip
                            , county_name
                            , city_name
                            , zipcnt
                            , RANK( ) OVER( PARTITION BY state, zip, county_name ORDER BY zipcnt DESC) otherziprank
                            , RANK( ) OVER( PARTITION BY state, zip ORDER BY county_name) othercountyrank
                   FROM   zones z
                   WHERE  NOT EXISTS ( SELECT 1
                                         FROM   gtsixty g
                                         WHERE  z.state = g.state
                                                AND z.zip = g.zip
                                       )
                            AND NOT EXISTS ( SELECT 1
                                             FROM   cities c
                                             WHERE  z.state = c.state
                                                    AND z.zip = c.zip
                                           )
                )
                , results AS (
                   SELECT state
                          , zip
                          , county_name
                          , city_name
                          , countytotal
                          , countyrank
                          , countyratio
                          , zipcnt
                          , gtrank
                          , cityrank
                          , alphacityrank
                          , overall_alphacityrank  -- crapp-2777
                          , zonecityrank
                          , otherziprank
                          , othercountyrank
                          , alphacountyrank        -- crapp-3880
                          , listrank
                          , RANK( ) OVER( PARTITION BY state, zip ORDER BY listrank) totalrank
                   FROM (
                          SELECT z.state
                                 , z.zip
                                 , z.county_name
                                 , z.city_name
                                 , z.zipcnt
                                 , z.countytotal
                                 , z.countyrank
                                 , z.countyratio
                                 , NVL(gt.gtrank, 9) gtrank
                                 , LPAD(NVL(c.cityrank, 99),2,0)        cityrank
                                 , LPAD(z.alphacityrank,2,0)            alphacityrank
                                 , LPAD(z.overall_alphacityrank,2,0)    overall_alphacityrank -- crapp-2777
                                 , LPAD(z.zonecityrank,2,0)             zonecityrank
                                 , LPAD(NVL(o.otherziprank, 99),2,0)    otherziprank
                                 , LPAD(NVL(o.othercountyrank, 99),2,0) othercountyrank
                                 , LPAD(NVL(z.alphacountyrank, 99),2,0) alphacountyrank       -- crapp-3880
                                 , TO_NUMBER(NVL(gt.gtrank,9)||
                                             LPAD(NVL(c.cityrank, 99),2,0)||
                                             LPAD(z.alphacityrank,2,0)||
                                             LPAD(z.overall_alphacityrank,2,0)||              -- crapp-2777
                                             LPAD(z.zonecityrank,2,0)||
                                             LPAD(NVL(o.otherziprank, 99),2,0)||
                                             LPAD(NVL(o.othercountyrank, 99),2,0)||
                                             LPAD(NVL(z.alphacountyrank, 99),2,0)             -- crapp-3880
                                            ) listrank
                          FROM   zones z
                                 LEFT JOIN gtsixty gt ON (    z.state       = gt.state
                                                          AND z.zip         = gt.zip
                                                          AND z.county_name = gt.county_name
                                                          AND z.city_name   = gt.city_name)
                                 LEFT JOIN cities c ON (    z.state       = c.state
                                                        AND z.county_name = c.county_name
                                                        AND z.city_name   = c.city_name
                                                        AND z.zip         = c.zip)
                                 LEFT JOIN other o ON (    z.state       = o.state
                                                       AND z.county_name = o.county_name
                                                       AND z.city_name   = o.city_name
                                                       AND z.zip         = o.zip)
                        )
                )
                SELECT state
                       , zip
                       , county_name
                       , city_name
                       , countyrank
                       , zonecityrank
                       , listrank
                       , totalrank
                       , TRIM(CASE WHEN totalrank = 1 THEN 'Y' ELSE NULL END) default_zip
                BULK COLLECT INTO v_zip5default
                FROM   results;

            FORALL d IN 1..v_zip5default.COUNT
                UPDATE gis_indata_areas_temp t
                    SET   t.county_rank = v_zip5default(d).countyrank
                        , t.city_rank   = v_zip5default(d).zonecityrank
                        , t.default_zip = v_zip5default(d).default_zip
                WHERE     t.state       = v_zip5default(d).state_code
                      AND t.county_name = v_zip5default(d).county_name
                      AND t.city_name   = v_zip5default(d).city_name
                      AND t.zip         = v_zip5default(d).zip;
            COMMIT;
            v_zip5default := t_zip5default();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Zip5 - gis_indata_areas_temp', paction=>1, puser=>user_i);


            -- ************************** --
            -- Update Default Zip4 (zip9) --
            -- ************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Zip4 (stage table) - gis_zipcount_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zipcount_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n3 UNUSABLE';

            --DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_indata_areas_temp', cascade => TRUE);  09/06/17, removed

            -- 09/02/15 - changed to collection --
            WITH stjs AS
                (   SELECT *
                    FROM ( SELECT DISTINCT
                                  state, zip, zip9, county_name, city_name, stj1_id, stj2_id, stj3_id
                                  , stj4_id, stj5_id, stj6_id, stj7_id, stj8_id, stj9_id, stj_name
                           FROM   gis_indata_areas_temp
                          )
                    UNPIVOT ( stjid FOR id IN (  stj1_id AS 1, stj2_id AS 2, stj3_id AS 3, stj4_id AS 4
                                               , stj5_id AS 5, stj6_id AS 6, stj7_id AS 7, stj8_id AS 8, stj9_id AS 9))
                )
                , stjcnt AS (
                    SELECT  zip
                            , zip9
                            , county_name
                            , city_name
                            , MAX(ID) stjcount
                            , stj_name
                    FROM    stjs
                    GROUP BY zip
                            , zip9
                            , county_name
                            , city_name
                            , stj_name
                )
                , zipcnt AS (
                    SELECT  zip
                            , zip9
                            , county_name
                            , city_name
                            , COUNT(biti_id) zipcount   -- crapp-3968, changed from zip9
                    FROM    gis_indata_areas_temp
                    GROUP BY zip
                            , zip9
                            , county_name
                            , city_name
                )
                , zones AS (
                    SELECT  /*+index (t gis_indata_areas_temp_n2)*/ DISTINCT
                            t.state
                            , t.zip9
                            , t.county_name
                            , t.city_name
                            , s.stj_name
                            , RANK( ) OVER( PARTITION BY t.state, t.zip9 ORDER BY z.zipcount DESC ) ziprank   -- crapp-3968, removed t.county_name, t.city_name
                            , RANK( ) OVER( PARTITION BY t.state, t.zip9 ORDER BY t.match_id ) matchrank
                            , DECODE(t.city_name, 'UNINCORPORATED', 1, 0) cityrank  -- Indicates an Actual City vs Unincorporated - crapp-2161
                            , RANK( ) OVER( PARTITION BY t.state, t.zip9 ORDER BY NVL(s.stjcount, 0) DESC) stjcount
                            , RANK( ) OVER( PARTITION BY t.state, t.zip9, t.county_name, t.city_name ORDER BY s.stj_name) stjrank   -- 09/02/15 - Alphabetical
                            , RANK( ) OVER( PARTITION BY t.state, t.zip9, t.county_name ORDER BY t.city_name ) alphacityrank
                            , RANK( ) OVER( PARTITION BY t.state, t.zip9 ORDER BY t.county_name ) countyrank
                    FROM    gis_indata_areas_temp t
                            LEFT JOIN stjcnt s ON (    t.zip9 = s.zip9
                                                   AND t.county_name = s.county_name
                                                   AND t.city_name   = s.city_name
                                                   AND t.stj_name    = s.stj_name
                                                  )
                            JOIN zipcnt z ON (    t.zip9 = z.zip9
                                              AND t.county_name = z.county_name
                                              AND t.city_name   = z.city_name
                                             )
                    WHERE   t.zip9 IS NOT NULL
                    GROUP BY t.zip9
                            , t.state
                            , t.county_name
                            , t.city_name
                            , s.stj_name
                            , t.match_id
                            , NVL(s.stjcount, 0)
                            , z.zipcount
                )
                , ranklist AS (
                    SELECT  state
                            , zip9
                            , county_name
                            , city_name
                            , stj_name
                            , ziprank
                            , matchrank
                            , cityrank
                            , stjcount
                            , stjrank
                            , alphacityrank
                            , countyrank
                            , (ziprank||matchrank||cityrank||stjcount||stjrank||alphacityrank||countyrank) totalrank -- 12/03/15 crapp-2161
                    FROM    zones
                )
                , results AS (
                    SELECT  state
                            , zip9
                            , county_name
                            , city_name
                            , stj_name
                            , RANK() OVER( PARTITION BY state, zip9 ORDER BY totalrank) totalrank
                    FROM    ranklist
                )
                SELECT state
                       , NULL zipcode
                       , zip9
                       , county_name
                       , city_name
                       , stj_name
                       , NULL zipcount
                       , NULL geo_area_key
                       , NULL state_name
                       , NULL citycount
                       , NULL match_id
                       , 'Y' default_zip4
                       , NULL hierarchy_level_id
                       , NULL area_id
                       --, totalrank
                BULK COLLECT INTO v_zipcnt
                FROM   results
                WHERE  totalrank = 1;

            FORALL i IN v_zipcnt.first..v_zipcnt.last
                INSERT INTO gis_zipcount_temp
                VALUES v_zipcnt(i);
            COMMIT;

            v_zipcnt := t_zipcnt();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Zip4 (stage table) - gis_zipcount_temp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes/stats (stage table) - gis_zipcount_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n3 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_zipcount_temp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes/stats (stage table) - gis_zipcount_temp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Zip4 (set flag) - gis_indata_areas_temp', paction=>0, puser=>user_i);
            MERGE /*+index(t gis_indata_areas_temp_n2) */ INTO gis_indata_areas_temp t
                USING (
                        SELECT /*+index(z gis_zipcount_temp_n2)*/
                               state
                               , zip9
                               , countyname
                               , cityname
                               , stjname
                        FROM   gis_zipcount_temp z
                      ) s ON (     t.state       = s.state
                               AND t.zip9        = s.zip9
                               AND t.county_name = s.countyname
                               AND t.city_name   = s.cityname
                               AND NVL(t.stj_name, 'N/A') = NVL(s.stjname, 'N/A')
                             )
                WHEN MATCHED THEN
                    UPDATE SET
                        t.default_zip4 = 'Y';
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Zip4 (set flag) - gis_indata_areas_temp', paction=>1, puser=>user_i);


            -- *************************** --
            -- Update Multiple City counts --
            -- *************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Multiple City counts - gis_indata_areas_temp', paction=>0, puser=>user_i);
            MERGE INTO gis_indata_areas_temp t
                USING ( WITH zones AS
                            (   SELECT  state
                                        , county_name
                                        , city_name
                                        , stj_name
                                        , zip
                                        , COUNT( DISTINCT zip9 ) zip4cnt
                                FROM    gis_indata_areas_temp
                                WHERE   zip9 IS NOT NULL
                                        AND state = stcode_i
                                GROUP BY
                                        state
                                        , county_name
                                        , city_name
                                        , stj_name
                                        , zip
                                ORDER BY
                                        zip
                                        , county_name
                                        , city_name
                            )
                            , citycnt AS (
                                SELECT  zip
                                        , county_name
                                        , COUNT( DISTINCT city_name ) cities
                                FROM    gis_indata_areas_temp
                                WHERE   zip9 IS NOT NULL
                                        AND state = stcode_i
                                GROUP BY zip,
                                        county_name
                                HAVING COUNT( DISTINCT city_name ) > 1
                            )
                            SELECT  DISTINCT
                                    z.zip
                                    , z.state
                                    , z.county_name
                                    , NVL(cc.cities, 0) multiple_cities
                            FROM    zones z
                                    JOIN citycnt cc ON  z.zip = cc.zip
                                                    AND z.county_name = cc.county_name
                      ) s ON (     t.state = s.state
                               AND t.zip   = s.zip
                               AND t.county_name = s.county_name
                             )
                WHEN MATCHED THEN
                    UPDATE SET
                        t.multiple_cities = s.multiple_cities;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Multiple City counts - gis_indata_areas_temp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_ranking', paction=>1, puser=>user_i);
        END update_ranking;



    -- ******************************************* --
    -- Function used during Get_DefaultZip process --
    -- ******************************************* --
    FUNCTION F_GetZip9Feed(pState_code IN VARCHAR2) RETURN t_zip9feed PIPELINED
    IS
        lo_feed r_zip9feed;
    BEGIN
        FOR r_row IN (
                    SELECT /*+index (z gis_zipcount_temp_n3)*/
                           state
                           , match_id geo_polygon_id
                           , geo_area_key
                           , hierarchy_level_id
                           , countyname
                           , zip9
                           , citycount multiple_cities
                           , area_id
                    FROM   gis_zipcount_temp z
                    WHERE  citycount = 1
                           AND state = pState_code
                )
        LOOP
            lo_feed.state               := r_row.state;
            lo_feed.geo_polygon_id      := r_row.geo_polygon_id;
            lo_feed.geo_area_key        := r_row.geo_area_key;
            lo_feed.hierarchy_level_id  := r_row.hierarchy_level_id;
            lo_feed.countyname          := r_row.countyname;
            lo_feed.zip9                := r_row.zip9;
            lo_feed.multiple_cities     := r_row.multiple_cities;
            lo_feed.area_id             := r_row.area_id;
            PIPE ROW(lo_feed);
        END LOOP;
    END F_GetZip9Feed;



    -- ****************************************** --
    -- Build GIS_DEFAULTZIPS_TEMP for USPS update --
    -- ****************************************** --
    PROCEDURE get_defaultzip (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) -- crapp-3177 - 06/05/17
    IS
            l_sql  VARCHAR2(1000 CHAR);
            l_hlvl NUMBER := 0;
            l_ccnt NUMBER := 0;

            TYPE t_zipcnt IS TABLE OF gis_zipcount_temp%ROWTYPE;
            v_zipcnt  t_zipcnt;

            TYPE t_polyzip IS TABLE OF gis_poly_zip_temp%ROWTYPE;
            v_polyzip  t_polyzip;

            TYPE t_defaultzip IS TABLE OF gis_defaultzips_temp%ROWTYPE;
            v_defaultzip  t_defaultzip;

            TYPE t_uspstmp IS TABLE OF gis_usps_temp%ROWTYPE;
            v_uspstmp  t_uspstmp;

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'get_defaultzip', paction=>0, puser=>user_i);

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_defaultzips_temp DROP STORAGE';

            -- ************ --
            -- State Values --
            -- ************ --

            gis_etl_p(pID_i, stcode_i, ' - Determine State level new zip9 records', 0, user_i);

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'State';

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_ids_temp DROP STORAGE';
            INSERT INTO gis_poly_ids_temp
                SELECT  DISTINCT
                        id
                        ,geo_area_key
                FROM    geo_polygons
                WHERE   hierarchy_level_id = l_hlvl
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                        AND next_rid IS NULL;
            COMMIT;

            -- Added 02/11/15 - to improve query performance --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            SELECT /*+index(t gis_indata_areas_temp_g1) index(gpi gis_poly_ids_n2)*/
                   DISTINCT
                   state_geo_area_key
                   , state_name
                   , state
                   , state_fips
                   , county_name
                   , county_fips
                   , city_name
                   , city_fips
                   , city_startdate
                   , city_enddate
                   , NULL stj_name
                   , NULL stj_fips
                   , NULL stj_enddate
                   , zip9
                   , zip
                   , zip4
                   , default_zip4
                   , city_rank
                   , gpi.id
                   , area_id
            BULK COLLECT INTO v_polyzip
            FROM   gis_indata_areas_temp t
                   JOIN gis_poly_ids_temp gpi ON (t.state_geo_area_key = gpi.geo_area_key)
            WHERE  state_geo_area_key IS NOT NULL
                   AND zip4 IS NOT NULL;

            FORALL i IN v_polyzip.first..v_polyzip.last
                INSERT INTO gis_poly_zip_temp
                VALUES v_polyzip(i);
            COMMIT;
            v_polyzip := t_polyzip();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            --EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';     -- 06/05/17, removed
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_defaultzips_stage DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 UNUSABLE';

            SELECT    p.id geo_polygon_id
                    , t.geo_area_key
                    , t.state_name
                    , t.state  state_code
                    , t.state_fips
                    , t.county_name
                    , t.county_fips
                    , t.city_name
                    , t.city_fips
                    , t.zip9
                    , t.zip
                    , t.zip4
                    , t.default_zip4
                    , t.city_rank
                    , 0 multiple_cities
                    , p.hierarchy_level_id
                    , NULL stjname
                    , t.area_id
            BULK COLLECT INTO v_defaultzip
            FROM    gis_poly_zip_temp t
                    JOIN geo_polygons p ON t.geo_poly_id = p.id -- crapp-3177, changed to geo_polygons from gis_zipcount_temp
            WHERE   t.state = stcode_i;

            FORALL i IN v_defaultzip.first..v_defaultzip.last
                INSERT INTO gis_defaultzips_stage
                VALUES v_defaultzip(i);
            COMMIT;
            v_defaultzip := t_defaultzip();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_defaultzips_stage', cascade => TRUE);


            -- Check to make sure Zip9 does not exist already in the USPS table --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_usps_temp DROP STORAGE';

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 UNUSABLE';
            SELECT /*+index(p geo_polygons_un)*/
                   DISTINCT
                   p.id
                   , p.hierarchy_level_id
                   , u.state_code
                   , u.county_name
                   , u.county_fips
                   , u.city_name
                   , u.city_fips
                   , u.zip
                   , SUBSTR(u.zip9, 6, 4)  zip4
                   , u.zip9
                   , NULL default_flag
                   , NULL geo_area_key
                   , NULL stj_fips
                   , u.area_id
                   , u.id usps_id
            BULK COLLECT INTO v_uspstmp
            FROM   geo_usps_lookup u
                   JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                   JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                     AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
            WHERE  u.state_code = stcode_i
                   AND p.hierarchy_level_id = l_hlvl
                   AND SUBSTR(u.zip9, 6, 4) IS NOT NULL
                   AND p.next_rid IS NULL;

            FORALL i IN v_uspstmp.first..v_uspstmp.last
                INSERT INTO gis_usps_temp
                VALUES v_uspstmp(i);
            COMMIT;
            v_uspstmp := t_uspstmp();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_temp', cascade => TRUE);

            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n2 UNUSABLE';

            INSERT INTO gis_defaultzips_temp
                (    geo_polygon_id
                    , geo_area_key
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip9
                    , zipcode
                    , zip4
                    , default_zip4
                    , city_rank
                    , multiple_cities
                    , hierarchy_level_id
                    , stjname
                    , area_id
                )
                SELECT /*+index(d gis_defaultzips_stage_n1)*/
                       DISTINCT
                         d.geo_polygon_id
                       , d.geo_area_key
                       , d.state_name
                       , d.state_code
                       , d.state_fips
                       , d.county_name
                       , d.county_fips
                       , d.city_name
                       , d.city_fips
                       , d.zip9
                       , d.zipcode
                       , d.zip4
                       , d.default_zip4
                       , d.city_rank
                       , d.multiple_cities
                       , d.hierarchy_level_id
                       , d.stjname
                       , d.area_id
                FROM   gis_defaultzips_stage d
                       JOIN (
                             SELECT geo_polygon_id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zipcode
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_defaultzips_stage
                             MINUS
                             SELECT id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zip
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_usps_temp
                            ) z ON d.geo_polygon_id  = z.geo_polygon_id
                                   AND d.state_code  = z.state_code
                                   AND d.county_name = z.county_name
                                   AND d.city_name   = z.city_name
                                   AND d.zipcode     = z.zipcode
                                   AND d.zip4        = z.zip4
                                   AND d.area_id     = z.area_id
                WHERE d.state_code = stcode_i;
            COMMIT;
            gis_etl_p(pID_i, stcode_i, ' - Determine State level new zip9 records', 1, user_i);



            -- ************* --
            -- County Values --
            -- ************* --

            gis_etl_p(pID_i, stcode_i, ' - Determine County level new zip9 records', 0, user_i);

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'County';

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_ids_temp DROP STORAGE';
            INSERT INTO gis_poly_ids_temp
                SELECT  DISTINCT
                        id
                        ,geo_area_key
                FROM    geo_polygons
                WHERE   hierarchy_level_id = l_hlvl
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                        AND next_rid IS NULL;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_ids_temp', cascade => TRUE);


            -- Added 02/11/15 - to improve query performance --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            SELECT /*+index(t gis_indata_areas_temp_g2) index(gpi gis_poly_ids_n2)*/
                   DISTINCT
                   county_geo_area_key
                   , state_name
                   , state
                   , state_fips
                   , county_name
                   , county_fips
                   , city_name
                   , city_fips
                   , city_startdate
                   , city_enddate
                   , NULL stj_name
                   , NULL stj_fips
                   , NULL stj_enddate
                   , zip9
                   , zip
                   , zip4
                   , default_zip4
                   , city_rank
                   , gpi.id
                   , area_id
            BULK COLLECT INTO v_polyzip
            FROM   gis_indata_areas_temp t
                   JOIN gis_poly_ids_temp gpi ON (t.county_geo_area_key = gpi.geo_area_key)
            WHERE  county_geo_area_key IS NOT NULL
                   AND zip4 IS NOT NULL;

            FORALL i IN v_polyzip.first..v_polyzip.last
                INSERT INTO gis_poly_zip_temp
                VALUES v_polyzip(i);
            COMMIT;
            v_polyzip := t_polyzip();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            --EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';     -- 06/05/17, removed
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_defaultzips_stage DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 UNUSABLE';
            SELECT    p.id geo_polygon_id
                    , t.geo_area_key
                    , t.state_name
                    , t.state  state_code
                    , t.state_fips
                    , t.county_name
                    , t.county_fips
                    , t.city_name
                    , t.city_fips
                    , t.zip9
                    , t.zip
                    , t.zip4
                    , t.default_zip4
                    , t.city_rank
                    , 0 multiple_cities
                    , p.hierarchy_level_id
                    , NULL stjname
                    , t.area_id
            BULK COLLECT INTO v_defaultzip
            FROM    gis_poly_zip_temp t
                    JOIN geo_polygons p ON t.geo_poly_id = p.id -- crapp-3177, changed to geo_polygons from gis_zipcount_temp
            WHERE   t.state = stcode_i;

            FORALL i IN v_defaultzip.first..v_defaultzip.last
                INSERT INTO gis_defaultzips_stage
                VALUES v_defaultzip(i);
            COMMIT;
            v_defaultzip := t_defaultzip();


            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_defaultzips_stage', cascade => TRUE);


            -- Check to make sure Zip9 does not exist already in the USPS table --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_usps_temp DROP STORAGE';

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 UNUSABLE';
            SELECT /*+index(p geo_polygons_un)*/
                   DISTINCT
                   p.id
                   , p.hierarchy_level_id
                   , u.state_code
                   , u.county_name
                   , u.county_fips
                   , u.city_name
                   , u.city_fips
                   , u.zip
                   , SUBSTR(u.zip9, 6, 4)  zip4
                   , u.zip9
                   , NULL default_flag
                   , NULL geo_area_key
                   , NULL stj_fips
                   , u.area_id
                   , u.id usps_id
            BULK COLLECT INTO v_uspstmp
            FROM   geo_usps_lookup u
                   JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                   JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                     AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
            WHERE  u.state_code = stcode_i
                   AND p.hierarchy_level_id = l_hlvl
                   AND SUBSTR(u.zip9, 6, 4) IS NOT NULL
                   AND p.next_rid IS NULL;

            FORALL i IN v_uspstmp.first..v_uspstmp.last
                INSERT INTO gis_usps_temp
                VALUES v_uspstmp(i);
            COMMIT;
            v_uspstmp := t_uspstmp();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_temp', cascade => TRUE);

            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n2 UNUSABLE';

            INSERT INTO gis_defaultzips_temp
                (    geo_polygon_id
                    , geo_area_key
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip9
                    , zipcode
                    , zip4
                    , default_zip4
                    , city_rank
                    , multiple_cities
                    , hierarchy_level_id
                    , stjname
                    , area_id
                )
                SELECT /*+index(d gis_defaultzips_stage_n1)*/
                       DISTINCT
                         d.geo_polygon_id
                       , d.geo_area_key
                       , d.state_name
                       , d.state_code
                       , d.state_fips
                       , d.county_name
                       , d.county_fips
                       , d.city_name
                       , d.city_fips
                       , d.zip9
                       , d.zipcode
                       , d.zip4
                       , d.default_zip4
                       , d.city_rank
                       , d.multiple_cities
                       , d.hierarchy_level_id
                       , d.stjname
                       , d.area_id
                FROM   gis_defaultzips_stage d
                       JOIN (
                             SELECT geo_polygon_id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zipcode
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_defaultzips_stage
                             MINUS
                             SELECT id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zip
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_usps_temp
                            ) z ON d.geo_polygon_id  = z.geo_polygon_id
                                   AND d.state_code  = z.state_code
                                   AND d.county_name = z.county_name
                                   AND d.city_name   = z.city_name
                                   AND d.zipcode     = z.zipcode
                                   AND d.zip4        = z.zip4
                                   AND d.area_id     = z.area_id
                WHERE d.state_code = stcode_i;
            COMMIT;
            gis_etl_p(pID_i, stcode_i, ' - Determine County level new zip9 records', 1, user_i);


            -- *********** --
            -- City Values --
            -- *********** --

            gis_etl_p(pID_i, stcode_i, ' - Determine City level new zip9 records', 0, user_i);

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'City';

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_ids_temp DROP STORAGE';
            INSERT INTO gis_poly_ids_temp
                SELECT  DISTINCT
                        id
                        ,geo_area_key
                FROM    geo_polygons
                WHERE   hierarchy_level_id = l_hlvl
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                        AND next_rid IS NULL;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_ids_temp', cascade => TRUE);


            -- Added 02/11/15 - to improve query performance --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            SELECT /*+index(t gis_indata_areas_temp_g3) index(gpi gis_poly_ids_n2)*/
                   DISTINCT
                   city_geo_area_key
                   , state_name
                   , state
                   , state_fips
                   , county_name
                   , county_fips
                   , city_name
                   , city_fips
                   , city_startdate
                   , city_enddate
                   , NULL stj_name
                   , NULL stj_fips
                   , NULL stj_enddate
                   , zip9
                   , zip
                   , zip4
                   , default_zip4
                   , city_rank
                   , gpi.id
                   , area_id
            BULK COLLECT INTO v_polyzip
            FROM   gis_indata_areas_temp t
                   JOIN gis_poly_ids_temp gpi ON (t.city_geo_area_key = gpi.geo_area_key)
            WHERE  city_geo_area_key IS NOT NULL;

            FORALL i IN v_polyzip.first..v_polyzip.last
                INSERT INTO gis_poly_zip_temp
                VALUES v_polyzip(i);
            COMMIT;
            v_polyzip := t_polyzip();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            --EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';     -- 06/05/17, removed
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_defaultzips_stage DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 UNUSABLE';
            SELECT  /*+index(p geo_polygons_pk)*/
                    DISTINCT
                    p.id geo_polygon_id
                    , t.geo_area_key
                    , t.state_name
                    , t.state state_code
                    , t.state_fips
                    , t.county_name
                    , t.county_fips
                    , t.city_name
                    , t.city_fips
                    , t.zip9
                    , t.zip
                    , t.zip4
                    , t.default_zip4
                    , t.city_rank
                    , 0 multiple_cities -- crapp-3177, changed to "0"
                    , p.hierarchy_level_id
                    , NULL stjname
                    , t.area_id
            BULK COLLECT INTO v_defaultzip
            FROM    gis_poly_zip_temp t
                    JOIN geo_polygons p ON t.geo_poly_id = p.id
            WHERE   t.state = stcode_i;

            FORALL i IN v_defaultzip.first..v_defaultzip.last
                INSERT INTO gis_defaultzips_stage
                VALUES v_defaultzip(i);
            COMMIT;
            v_defaultzip := t_defaultzip();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_defaultzips_stage', cascade => TRUE);


            -- Check to make sure Zip9 does not exist already in the USPS table
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_usps_temp DROP STORAGE';

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 UNUSABLE';
            SELECT /*+index(p geo_polygons_un)*/
                   DISTINCT
                   p.id
                   , p.hierarchy_level_id
                   , u.state_code
                   , u.county_name
                   , u.county_fips
                   , u.city_name
                   , u.city_fips
                   , u.zip
                   , SUBSTR(u.zip9, 6, 4)  zip4
                   , u.zip9
                   , NULL default_flag
                   , NULL geo_area_key
                   , NULL stj_fips
                   , u.area_id
                   , u.id usps_id
            BULK COLLECT INTO v_uspstmp
            FROM   geo_usps_lookup u
                   JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                   JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                     AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
            WHERE  u.state_code = stcode_i
                   AND p.hierarchy_level_id = l_hlvl
                   --AND SUBSTR(u.zip9, 6, 4) IS NOT NULL  -- City version we want all Zips
                   AND p.next_rid IS NULL;

            FORALL i IN v_uspstmp.first..v_uspstmp.last
                INSERT INTO gis_usps_temp
                VALUES v_uspstmp(i);
            COMMIT;
            v_uspstmp := t_uspstmp();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_temp', cascade => TRUE);


            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n2 UNUSABLE';

            -- Zip4 IS NOT NULL --
            INSERT INTO gis_defaultzips_temp
                (    geo_polygon_id
                    , geo_area_key
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip9
                    , zipcode
                    , zip4
                    , default_zip4
                    , city_rank
                    , multiple_cities
                    , hierarchy_level_id
                    , stjname
                    , area_id
                )
                SELECT /*+index(d gis_defaultzips_stage_n1)*/
                       DISTINCT
                         d.geo_polygon_id
                       , d.geo_area_key
                       , d.state_name
                       , d.state_code
                       , d.state_fips
                       , d.county_name
                       , d.county_fips
                       , d.city_name
                       , d.city_fips
                       , d.zip9
                       , d.zipcode
                       , d.zip4
                       , d.default_zip4
                       , d.city_rank
                       , d.multiple_cities
                       , d.hierarchy_level_id
                       , d.stjname
                       , d.area_id
                FROM   gis_defaultzips_stage d
                       JOIN (
                             SELECT geo_polygon_id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zipcode
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_defaultzips_stage
                             WHERE  zip4 IS NOT NULL
                             MINUS
                             SELECT id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zip
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_usps_temp
                             WHERE  zip4 IS NOT NULL
                            ) z ON d.geo_polygon_id  = z.geo_polygon_id
                                   AND d.state_code  = z.state_code
                                   AND d.county_name = z.county_name
                                   AND d.city_name   = z.city_name
                                   AND d.zipcode     = z.zipcode
                                   AND d.zip4        = z.zip4
                                   AND d.area_id     = z.area_id
                WHERE d.state_code = stcode_i;
            COMMIT;

            -- Zip4 IS NULL --
            INSERT INTO gis_defaultzips_temp
                (    geo_polygon_id
                    , geo_area_key
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip9
                    , zipcode
                    , zip4
                    , default_zip4
                    , city_rank
                    , multiple_cities
                    , hierarchy_level_id
                    , stjname
                    , area_id
                )
                SELECT /*+index(d gis_defaultzips_stage_n1)*/
                       DISTINCT
                         d.geo_polygon_id
                       , d.geo_area_key
                       , d.state_name
                       , d.state_code
                       , d.state_fips
                       , d.county_name
                       , d.county_fips
                       , d.city_name
                       , d.city_fips
                       , d.zip9
                       , d.zipcode
                       , d.zip4
                       , d.default_zip4
                       , d.city_rank
                       , d.multiple_cities
                       , d.hierarchy_level_id
                       , d.stjname
                       , d.area_id
                FROM   gis_defaultzips_stage d
                       JOIN (
                             SELECT geo_polygon_id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zipcode
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_defaultzips_stage
                             WHERE  zip4 IS NULL
                             MINUS
                             SELECT id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zip
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_usps_temp
                             WHERE  zip4 IS NULL
                            ) z ON d.geo_polygon_id  = z.geo_polygon_id
                                   AND d.state_code  = z.state_code
                                   AND d.county_name = z.county_name
                                   AND d.city_name   = z.city_name
                                   AND d.area_id     = z.area_id
                                   AND d.zipcode     = z.zipcode
                                   AND NVL(d.zip4,'zip4') = NVL(z.zip4,'zip4')
                WHERE d.state_code = stcode_i;
            COMMIT;
            gis_etl_p(pID_i, stcode_i, ' - Determine City level new zip9 records', 1, user_i);


            -- ********** --
            -- STJ Values --
            -- ********** --

            gis_etl_p(pID_i, stcode_i, ' - Determine District level new zip9 records', 0, user_i);

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'District';

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_ids_temp';
            INSERT INTO gis_poly_ids_temp
                SELECT  DISTINCT
                        id
                        ,geo_area_key
                FROM    geo_polygons
                WHERE   hierarchy_level_id = l_hlvl
                        AND SUBSTR(geo_area_key, 1, 2) = stcode_i
                        AND next_rid IS NULL;
            COMMIT;

            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zipcount_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n3 UNUSABLE';

            -- Get city counts --
            FOR i IN 1..9 LOOP <<stj_loop>>
                gis_etl_p(pID_i, stcode_i, '   - STJ ' || i || ' records, gis_zipcount_temp', 0, user_i);

                l_sql := 'SELECT  /*+index(t gis_indata_areas_temp_g4) index(gpi geo_poly_ids_n2)*/ '||
                                  'state '||
                                  ', NULL zipcode '||
                                  ', zip9 '||
                                  ', county_name '||
                                  ', NULL cityname '||
                                  ', NULL stjname '||
                                  ', NULL zipcount '||
                                  ', stj' || i || '_geo_area_key geo_area_key '||
                                  ', state_name '||
                                  ', COUNT(DISTINCT city_name) citycount '||
                                  ', gpi.id match_id '||
                                  ', NULL  defaultzip '||
                                  ', ' || l_hlvl || ' hierarchy_level_id '||
                                  ', area_id '||
                         'FROM    gis_indata_areas_temp t '||
                                  'JOIN gis_poly_ids_temp gpi ON (t.stj' || i || '_geo_area_key = gpi.geo_area_key) '||
                         'WHERE   stj' || i || '_geo_area_key IS NOT NULL '||
                                  'AND state = ''' || stcode_i || ''' '||
                         'GROUP BY gpi.id '||
                                  ', stj' || i || '_geo_area_key '||
                                  ', state_name '||
                                  ', state '||
                                  ', county_name '||
                                  ', zip9 '||
                                  ', area_id ';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_zipcnt;

                FORALL i IN v_zipcnt.first..v_zipcnt.last
                    INSERT INTO gis_zipcount_temp
                    VALUES v_zipcnt(i);
                COMMIT;
                v_zipcnt := t_zipcnt();

                gis_etl_p(pID_i, stcode_i, '   - STJ ' || i || ' records, gis_zipcount_temp', 1, user_i);
            END LOOP stj_loop;

            gis_etl_p(pID_i, stcode_i, '   - Rebuild indexes and stats, gis_zipcount_temp', 0, user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zipcount_temp_n3 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_zipcount_temp', cascade => TRUE);
            gis_etl_p(pID_i, stcode_i, '   - Rebuild indexes and stats, gis_zipcount_temp', 1, user_i);


            -- crapp-3177 - New staging table for performance --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_defaultzips_stage DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 UNUSABLE';

            -- Updated 01/23/15 dlg - to split in to two queries --
            FOR i IN 1..9 LOOP <<count1_loop>>
                gis_etl_p(pID_i, stcode_i, '   - STJ ' || i || ' citycount > 1, gis_defaultzips_stage', 0, user_i);

                l_sql := 'SELECT  /*+index(t gis_indata_areas_temp_g4)*/ '||
                                  'DISTINCT '||
                                  ' s.geo_polygon_id '||
                                  ', t.stj' || i || '_geo_area_key  geo_area_key '||
                                  ', t.state_name '||
                                  ', t.state state_code '||
                                  ', t.state_fips '||
                                  ', t.county_name '||
                                  ', t.county_fips '||
                                  ', t.city_name '||
                                  ', t.city_fips '||
                                  ', t.zip9 '||
                                  ', t.zip '||
                                  ', t.zip4 '||
                                  ', t.default_zip4 '||
                                  ', t.city_rank '||
                                  ', s.citycount  multiple_cities '||
                                  ', s.hierarchy_level_id '||
                                  ', t.stj' || i || '_name stjname '||
                                  ', t.area_id '||
                         'FROM    gis_indata_areas_temp t '||
                                  'JOIN ( SELECT /*+index (z gis_zipcount_temp_n3)*/ '||
                                                'state '||
                                                ', match_id  geo_polygon_id '||
                                                ', geo_area_key '||
                                                ', hierarchy_level_id '||
                                                ', countyname '||
                                                ', zip9 '||
                                                ', citycount '||
                                                ', area_id '||
                                         'FROM   gis_zipcount_temp z '||
                                         'WHERE  citycount > 1 '||
                                       ') s ON (     t.state = s.state '||
                                                'AND t.stj' || i || '_geo_area_key = s.geo_area_key '||
                                                'AND t.county_name = s.countyname '||
                                                'AND t.zip9        = s.zip9 '||
                                                'AND t.area_id     = s.area_id '||
                                              ')';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_defaultzip;

                FORALL i IN v_defaultzip.first..v_defaultzip.last
                    INSERT INTO gis_defaultzips_stage
                    VALUES v_defaultzip(i);
                COMMIT;
                v_defaultzip := t_defaultzip();

                gis_etl_p(pID_i, stcode_i, '   - STJ ' || i || ' citycount > 1, gis_defaultzips_stage', 1, user_i);
            END LOOP count1_loop;


            -- Added 02/11/15 dlg - to improve query performance --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            FOR i IN 1..9 LOOP
                gis_etl_p(pID_i, stcode_i, '   - STJ ' || i || ', gis_poly_zip_temp', 0, user_i);

                l_sql := 'SELECT /*+index(t gis_indata_areas_temp_g4)*/ '||
                                 'DISTINCT '||
                                 'stj' || i || '_geo_area_key '||
                                 ', state_name '||
                                 ', state '||
                                 ', state_fips '||
                                 ', county_name '||
                                 ', county_fips '||
                                 ', city_name '||
                                 ', city_fips '||
                                 ', city_startdate '||
                                 ', city_enddate '||
                                 ', stj' || i || '_name     stj_name '||
                                 ', stj' || i || '_id       stj_fips '||
                                 ', stj' || i || '_enddate  stj_enddate '||
                                 ', zip9 '||
                                 ', zip '||
                                 ', zip4 '||
                                 ', default_zip4 '||
                                 ', city_rank '||
                                 ', gpi.id '||
                                 ', t.area_id '||
                         'FROM   gis_indata_areas_temp t '||
                                 'JOIN gis_poly_ids_temp gpi ON (t.stj' || i || '_geo_area_key = gpi.geo_area_key) '||
                         'WHERE  stj' || i || '_geo_area_key IS NOT NULL '||
                                 'AND zip4 IS NOT NULL ';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_polyzip;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;
                v_polyzip := t_polyzip();

                gis_etl_p(pID_i, stcode_i, '   - STJ ' || i || ', gis_poly_zip_temp', 1, user_i);
            END LOOP;

            gis_etl_p(pID_i, stcode_i, '   - Rebuild indexes and stats, gis_poly_zip_temp', 0, user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);
            gis_etl_p(pID_i, stcode_i, '   - Rebuild indexes and stats, gis_poly_zip_temp', 1, user_i);


            -- 09/24/15 - changed to a Piped Feed Insert due to memory issues --
            gis_etl_p(pID_i, stcode_i, '   - Piped insert, gis_defaultzips_stage', 0, user_i);
            INSERT INTO gis_defaultzips_stage -- crapp-3177, using staging table for performance
                SELECT  /*+index(t gis_poly_zip_temp_n2)*/
                        s.geo_polygon_id
                        , t.geo_area_key
                        , t.state_name
                        , t.state state_code
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.zip9
                        , t.zip
                        , t.zip4
                        , t.default_zip4
                        , t.city_rank
                        , s.multiple_cities
                        , s.hierarchy_level_id
                        , NULL stjname
                        , t.area_id
                FROM    gis_poly_zip_temp t
                        JOIN TABLE(load_gis.F_GetZip9Feed(stcode_i)) s ON (     t.geo_poly_id = s.geo_polygon_id
                                                                            AND t.county_name = s.countyname
                                                                            AND t.zip9        = s.zip9
                                                                            AND t.area_id     = s.area_id
                                                                          );
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_stage_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_defaultzips_stage', cascade => TRUE);
            gis_etl_p(pID_i, stcode_i, '   - Piped insert, gis_defaultzips_stage', 1, user_i);

            -- Check to make sure Zip9 does not exist already in the USPS table --
            gis_etl_p(pID_i, stcode_i, '  - Check if Zip9 already exists, gis_usps_temp', 0, user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_usps_temp DROP STORAGE';

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 UNUSABLE';
            SELECT /*+index(p geo_polygons_un)*/
                   DISTINCT
                   p.id
                   , p.hierarchy_level_id
                   , u.state_code
                   , u.county_name
                   , u.county_fips
                   , u.city_name
                   , u.city_fips
                   , u.zip
                   , SUBSTR(u.zip9, 6, 4)  zip4
                   , u.zip9
                   , NULL default_flag
                   , NULL geo_area_key
                   , NULL stj_fips
                   , u.area_id
                   , u.id usps_id
            BULK COLLECT INTO v_uspstmp
            FROM   geo_usps_lookup u
                   JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                   JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                     AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
            WHERE  u.state_code = stcode_i
                   AND p.hierarchy_level_id = l_hlvl
                   AND SUBSTR(u.zip9, 6, 4) IS NOT NULL
                   AND p.next_rid IS NULL;

            FORALL i IN v_uspstmp.first..v_uspstmp.last
                INSERT INTO gis_usps_temp
                VALUES v_uspstmp(i);
            COMMIT;
            v_uspstmp := t_uspstmp();

            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_temp', cascade => TRUE);
            gis_etl_p(pID_i, stcode_i, '  - Check if Zip9 already exists, gis_usps_temp', 1, user_i);

            gis_etl_p(pID_i, stcode_i, '  - Check if Zip9 already exists, gis_defaultzips_temp', 0, user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n2 UNUSABLE';

            INSERT INTO gis_defaultzips_temp
                (    geo_polygon_id
                    , geo_area_key
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip9
                    , zipcode
                    , zip4
                    , default_zip4
                    , city_rank
                    , multiple_cities
                    , hierarchy_level_id
                    , stjname
                    , area_id
                )
                SELECT /*+index(d gis_defaultzips_stage_n1)*/
                       DISTINCT
                         d.geo_polygon_id
                       , d.geo_area_key
                       , d.state_name
                       , d.state_code
                       , d.state_fips
                       , d.county_name
                       , d.county_fips
                       , d.city_name
                       , d.city_fips
                       , d.zip9
                       , d.zipcode
                       , d.zip4
                       , d.default_zip4
                       , d.city_rank
                       , d.multiple_cities
                       , d.hierarchy_level_id
                       , d.stjname
                       , d.area_id
                FROM   gis_defaultzips_stage d
                       JOIN (
                             SELECT geo_polygon_id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zipcode
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_defaultzips_stage
                             MINUS
                             SELECT id
                                    , hierarchy_level_id
                                    , state_code
                                    , county_name
                                    , city_name
                                    , zip
                                    , zip4
                                    , zip9
                                    , area_id
                             FROM   gis_usps_temp
                            ) z ON d.geo_polygon_id  = z.geo_polygon_id
                                   AND d.state_code  = z.state_code
                                   AND d.county_name = z.county_name
                                   AND d.city_name   = z.city_name
                                   AND d.zipcode     = z.zipcode
                                   AND d.zip4        = z.zip4
                                   AND d.area_id     = z.area_id
                WHERE d.state_code = stcode_i;
            COMMIT;
            gis_etl_p(pID_i, stcode_i, '  - Check if Zip9 already exists, gis_defaultzips_temp', 1, user_i);

            gis_etl_p(pID_i, stcode_i, '  - Rebuild indexes and stats, gis_defaultzips_temp', 0, user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_defaultzips_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_defaultzips_temp', cascade => TRUE);
            gis_etl_p(pID_i, stcode_i, '  - Rebuild indexes and stats, gis_defaultzips_temp', 1, user_i);

            gis_etl_p(pID_i, stcode_i, ' - Determine District level new zip9 records', 1, user_i);


            -- ******************* --
            -- Temp table clean-up --
            -- ******************* --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zipcount_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_usps_temp DROP STORAGE';
            COMMIT;

            gis_etl_p(pID_i, stcode_i, 'get_defaultzip', 1, user_i);
        END get_defaultzip;



    -- ******************************************************* --
    -- Determine current USPS records                          --
    -- ******************************************************* --
    PROCEDURE get_usps_staging (stcode_i VARCHAR2, user_i NUMBER, pID_i NUMBER) -- 06/19/17 - performance improvements and logging
    IS
            l_recs   NUMBER := 0;
            l_hlvl   NUMBER := 0;
            l_ccnt   NUMBER := 0;
            l_sup    NUMBER := 0;
            l_sql    VARCHAR2(2000 CHAR);

            TYPE t_polyzip IS TABLE OF gis_poly_zip_temp%ROWTYPE;
            v_polyzip  t_polyzip;

            TYPE t_uspstmp IS TABLE OF gis_usps_temp%ROWTYPE;
            v_uspstmp  t_uspstmp;

            CURSOR usps_stage IS
                SELECT /*+index(p geo_polygons_un)*/
                       DISTINCT
                       p.id
                       , p.hierarchy_level_id
                       , u.state_code
                       , u.county_name
                       , u.county_fips
                       , u.city_name
                       , u.city_fips
                       , u.zip
                       , SUBSTR(u.zip9, 6, 4)  zip4
                       , u.zip9
                       , NULL default_flag
                       , p.geo_area_key
                       , NULL stj_fips
                       , u.area_id
                       , u.id usps_id
                FROM   geo_usps_lookup u
                       JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                       JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                         AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
                WHERE  u.state_code = stcode_i
                       AND p.next_rid IS NULL;

            CURSOR polyzip_city IS
                SELECT  /*+index(t gis_indata_areas_temp_g3) index(p geo_polygons_n2)*/
                        DISTINCT
                        t.city_geo_area_key  geo_area_key
                        , t.state_name
                        , t.state
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.city_startdate
                        , t.city_enddate
                        , NULL stj_name
                        , NULL stj_fips
                        , NULL stj_enddate
                        , t.zip9
                        , t.zip
                        , t.zip4
                        , default_zip default_zip4
                        , CASE WHEN default_city = 'Y' THEN 1 ELSE NULL END city_rank
                        , p.id  geo_poly_id
                        , t.area_id
                FROM    gis_indata_areas_temp t
                        JOIN geo_polygons p ON (t.city_geo_area_key = p.geo_area_key)
                WHERE   t.state = stcode_i
                        AND t.city_geo_area_key IS NOT NULL;

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get USPS records - gis_usps_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_usps_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 UNUSABLE';

            OPEN usps_stage;
            LOOP
                FETCH usps_stage BULK COLLECT INTO v_uspstmp LIMIT 25000;

                FORALL i IN v_uspstmp.first..v_uspstmp.last
                    INSERT INTO gis_usps_temp
                    VALUES v_uspstmp(i);
                COMMIT;
                v_uspstmp := t_uspstmp();

                EXIT WHEN usps_stage%NOTFOUND;
            END LOOP;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get USPS records - gis_usps_temp', paction=>1, puser=>user_i);

            COMMIT;
            CLOSE usps_stage;

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Rebuild indexes and stats - gis_usps_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_usps_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_temp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Rebuild indexes and stats - gis_usps_temp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get state input records - gis_poly_zip_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_zip_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 UNUSABLE';

            SELECT  /*+index(t gis_indata_areas_temp_g1) index(p geo_polygons_n2)*/
                    DISTINCT
                    t.state_geo_area_key  geo_area_key
                    , t.state_name
                    , t.state
                    , t.state_fips
                    , t.county_name
                    , t.county_fips
                    , t.city_name
                    , t.city_fips
                    , t.city_startdate
                    , t.city_enddate
                    , NULL stj_name
                    , NULL stj_fips
                    , NULL stj_enddate
                    , t.zip9
                    , t.zip
                    , t.zip4
                    , default_zip default_zip4
                    , CASE WHEN default_city = 'Y' THEN 1 ELSE NULL END city_rank
                    , p.id  geo_poly_id
                    , t.area_id
            BULK COLLECT INTO v_polyzip
            FROM    gis_indata_areas_temp t
                    JOIN geo_polygons p ON (t.state_geo_area_key = p.geo_area_key)
            WHERE   state_geo_area_key IS NOT NULL;

            FORALL i IN v_polyzip.first..v_polyzip.last
                INSERT INTO gis_poly_zip_temp
                VALUES v_polyzip(i);
            COMMIT;

            v_polyzip := t_polyzip();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get state input records - gis_poly_zip_temp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get county input records - gis_poly_zip_temp', paction=>0, puser=>user_i);
            SELECT  /*+index(t gis_indata_areas_temp_g2) index(p geo_polygons_n2)*/
                    DISTINCT
                    t.county_geo_area_key  geo_area_key
                    , t.state_name
                    , t.state
                    , t.state_fips
                    , t.county_name
                    , t.county_fips
                    , t.city_name
                    , t.city_fips
                    , t.city_startdate
                    , t.city_enddate
                    , NULL stj_name
                    , NULL stj_fips
                    , NULL stj_enddate
                    , t.zip9
                    , t.zip
                    , t.zip4
                    , default_zip default_zip4
                    , CASE WHEN default_city = 'Y' THEN 1 ELSE NULL END city_rank
                    , p.id  geo_poly_id
                    , t.area_id
            BULK COLLECT INTO v_polyzip
            FROM    gis_indata_areas_temp t
                    JOIN geo_polygons p ON (t.county_geo_area_key = p.geo_area_key)
            WHERE   county_geo_area_key IS NOT NULL;

            FORALL i IN v_polyzip.first..v_polyzip.last
                INSERT INTO gis_poly_zip_temp
                VALUES v_polyzip(i);
            COMMIT;

            v_polyzip := t_polyzip();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get county input records - gis_poly_zip_temp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get city input records - gis_poly_zip_temp', paction=>0, puser=>user_i);
            OPEN polyzip_city;
            LOOP
                FETCH polyzip_city BULK COLLECT INTO v_polyzip LIMIT 25000;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;
                v_polyzip := t_polyzip();

                EXIT WHEN polyzip_city%NOTFOUND;
            END LOOP;
            COMMIT;
            CLOSE polyzip_city;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get city input records - gis_poly_zip_temp', paction=>1, puser=>user_i);


            -- ****************************************** --
            -- Include Suuplemental UAS data - crapp-2152 --
            -- ****************************************** --
            SELECT COUNT(*)
            INTO   l_sup
            FROM   gis_indata_areas_sup_temp;

            IF l_sup > 0 THEN
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get supplemental input records - gis_poly_zip_temp', paction=>0, puser=>user_i);
                SELECT  /*+index(t gis_indata_areas_sup_temp_g1) index(p geo_polygons_n2)*/
                        DISTINCT
                        t.state_geo_area_key  geo_area_key
                        , t.state_name
                        , t.state
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.city_startdate
                        , t.city_enddate
                        , NULL stj_name
                        , NULL stj_fips
                        , NULL stj_enddate
                        , t.zip9
                        , t.zip
                        , t.zip4
                        , default_zip default_zip4
                        , CASE WHEN default_city = 'Y' THEN 1 ELSE NULL END city_rank
                        , p.id  geo_poly_id
                        , t.area_id
                BULK COLLECT INTO v_polyzip
                FROM    gis_indata_areas_sup_temp t
                        JOIN geo_polygons p ON (t.state_geo_area_key = p.geo_area_key)
                WHERE   state_geo_area_key IS NOT NULL;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;

                v_polyzip := t_polyzip();

                SELECT  /*+index(t gis_indata_areas_sup_temp_g2) index(p geo_polygons_n2)*/
                        DISTINCT
                        t.county_geo_area_key  geo_area_key
                        , t.state_name
                        , t.state
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.city_startdate
                        , t.city_enddate
                        , NULL stj_name
                        , NULL stj_fips
                        , NULL stj_enddate
                        , t.zip9
                        , t.zip
                        , t.zip4
                        , default_zip default_zip4
                        , CASE WHEN default_city = 'Y' THEN 1 ELSE NULL END city_rank
                        , p.id  geo_poly_id
                        , t.area_id
                BULK COLLECT INTO v_polyzip
                FROM    gis_indata_areas_sup_temp t
                        JOIN geo_polygons p ON (t.county_geo_area_key = p.geo_area_key)
                WHERE   county_geo_area_key IS NOT NULL;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;

                v_polyzip := t_polyzip();

                SELECT  /*+index(t gis_indata_areas_sup_temp_g3) index(p geo_polygons_n2)*/
                        DISTINCT
                        t.city_geo_area_key  geo_area_key
                        , t.state_name
                        , t.state
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.city_startdate
                        , t.city_enddate
                        , NULL stj_name
                        , NULL stj_fips
                        , NULL stj_enddate
                        , t.zip9
                        , t.zip
                        , t.zip4
                        , default_zip default_zip4
                        , CASE WHEN default_city = 'Y' THEN 1 ELSE NULL END city_rank
                        , p.id  geo_poly_id
                        , t.area_id
                BULK COLLECT INTO v_polyzip
                FROM    gis_indata_areas_sup_temp t
                        JOIN geo_polygons p ON (t.city_geo_area_key = p.geo_area_key)
                WHERE   city_geo_area_key IS NOT NULL;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;

                v_polyzip := t_polyzip();
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get supplemental input records - gis_poly_zip_temp', paction=>1, puser=>user_i);
            END IF; -- supplemental record count > 0


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get stj input records - gis_poly_zip_temp', paction=>0, puser=>user_i);
            FOR i IN 1..9 LOOP
                l_sql := 'SELECT  /*+index(t gis_indata_areas_temp_g4) index(p geo_polygons_n2)*/ '||
                                  'DISTINCT '||
                                  't.stj' || i || '_geo_area_key  geo_area_key '||
                                  ', t.state_name '||
                                  ', t.state '||
                                  ', t.state_fips '||
                                  ', t.county_name '||
                                  ', t.county_fips '||
                                  ', t.city_name '||
                                  ', t.city_fips '||
                                  ', t.city_startdate '||
                                  ', t.city_enddate '||
                                  ', t.stj' || i || '_name    stj_name '||
                                  ', t.stj' || i || '_id      stj_fips '||
                                  ', t.stj' || i || '_enddate stj_enddate '||
                                  ', t.zip9 '||
                                  ', t.zip '||
                                  ', t.zip4 '||
                                  ', default_zip default_zip4 '||
                                  ', CASE WHEN default_city = ''Y'' THEN 1 ELSE NULL END city_rank '||
                                  ', p.id '||
                                  ', t.area_id '||
                          'FROM    gis_indata_areas_temp t '||
                                  'JOIN geo_polygons p ON (t.stj' || i || '_geo_area_key = p.geo_area_key) '||
                          'WHERE   stj' || i || '_geo_area_key IS NOT NULL ';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_polyzip;

                FORALL i IN v_polyzip.first..v_polyzip.last
                    INSERT INTO gis_poly_zip_temp
                    VALUES v_polyzip(i);
                COMMIT;

                v_polyzip := t_polyzip();

                -- Supplemental UAS - crapp-2152 --
                IF l_sup > 0 THEN
                    l_sql := 'SELECT  /*+index(t gis_indata_areas_sup_temp_g4) index(p geo_polygons_n2)*/ '||
                                      'DISTINCT '||
                                      't.stj' || i || '_geo_area_key  geo_area_key '||
                                      ', t.state_name '||
                                      ', t.state '||
                                      ', t.state_fips '||
                                      ', t.county_name '||
                                      ', t.county_fips '||
                                      ', t.city_name '||
                                      ', t.city_fips '||
                                      ', t.city_startdate '||
                                      ', t.city_enddate '||
                                      ', t.stj' || i || '_name    stj_name '||
                                      ', t.stj' || i || '_id      stj_fips '||
                                      ', t.stj' || i || '_enddate stj_enddate '||
                                      ', t.zip9 '||
                                      ', t.zip '||
                                      ', t.zip4 '||
                                      ', default_zip default_zip4 '||
                                      ', CASE WHEN default_city = ''Y'' THEN 1 ELSE NULL END city_rank '||
                                      ', p.id '||
                                      ', t.area_id '||
                              'FROM    gis_indata_areas_sup_temp t '||
                                      'JOIN geo_polygons p ON (t.stj' || i || '_geo_area_key = p.geo_area_key) '||
                              'WHERE   stj' || i || '_geo_area_key IS NOT NULL ';

                    EXECUTE IMMEDIATE l_sql
                    BULK COLLECT INTO v_polyzip;

                    FORALL i IN v_polyzip.first..v_polyzip.last
                        INSERT INTO gis_poly_zip_temp
                        VALUES v_polyzip(i);
                    COMMIT;

                    v_polyzip := t_polyzip();
                END IF;

            END LOOP;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get stj input records - gis_poly_zip_temp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Rebuild indexes and stats - gis_poly_zip_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_poly_zip_temp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_zip_temp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Rebuild indexes and stats - gis_poly_zip_temp', paction=>1, puser=>user_i);
        END get_usps_staging;



    -- ****************************************************************** --
    -- Update GEO_POLYGON_USPS with Changes from GIS                      --
    -- ****************************************************************** --
    -- 06/03/15 - Using gis_indata_areas_temp                             --
    -- 08/14/15 - Added "get_usps_staging" procedure                      --
    -- 09/08/15 - Added pID_i for logging progress                        --
    -- 09/30/15 - Added Zips_Removed Cursor to include Zips being removed --
    -- ****************************************************************** --
    FUNCTION update_geo_polygon_usps (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER, type_i IN VARCHAR2) RETURN NUMBER    -- 09/21/17 - crapp-3845
    IS
            l_usps_pk  geo_polygon_usps.id%TYPE;
            l_status   NUMBER := 0;
            l_recs     NUMBER := 0;
            l_hlvl     NUMBER := 0;
            l_ccnt     NUMBER := 0;
            l_stdate   DATE;

            -- 09/30/15 - crapp-2089
            CURSOR zips_removed IS
                SELECT  DISTINCT
                        u.id, u.geo_area_key, u.state_code, u.county_name, u.city_name, u.area_id, u.usps_id, u.zip
                FROM    gis_usps_temp u
                        JOIN (
                              SELECT  DISTINCT id, geo_area_key, state_code, county_name, county_fips, city_name, city_fips, zip, area_id
                              FROM    gis_usps_temp
                              WHERE   zip IS NOT NULL
                                      AND zip9 IS NULL
                              MINUS
                              SELECT  DISTINCT geo_poly_id, geo_area_key, state, county_name, county_fips, city_name, city_fips, zip, area_id
                              FROM    gis_poly_zip_temp
                           ) d ON  u.area_id      = d.area_id
                               AND u.state_code   = d.state_code
                               AND u.geo_area_key = d.geo_area_key
                               AND u.zip          = d.zip
                WHERE   u.zip IS NOT NULL
                        AND u.zip9 IS NULL
                ORDER BY u.zip, u.area_id, u.id;


            CURSOR null_zipsremoved IS
                SELECT  u.id, u.geo_area_key, u.state_code, u.county_name, u.city_name, u.area_id, u.usps_id, u.zip
                FROM    gis_usps_temp u
                        JOIN (
                              SELECT  DISTINCT id, geo_area_key, state_code, county_name, county_fips, city_name, city_fips, area_id
                              FROM    gis_usps_temp
                              WHERE   zip IS NULL
                              MINUS
                              SELECT  DISTINCT geo_poly_id, geo_area_key, state, county_name, county_fips, city_name, city_fips, area_id
                              FROM    gis_poly_zip_temp
                           ) d ON  u.area_id      = d.area_id
                               AND u.state_code   = d.state_code
                               AND u.geo_area_key = d.geo_area_key
                WHERE   u.zip IS NULL   -- 09/30/15 - added crapp-2089
                ORDER BY u.area_id, u.geo_area_key;


            CURSOR zip9removed IS
                  SELECT  id, geo_area_key, state_code, county_name, county_fips, city_name, city_fips, zip, zip9, area_id, usps_id
                  FROM    gis_usps_temp u
                  WHERE   zip9 IS NOT NULL
                          AND NOT EXISTS (
                                          SELECT  1
                                          FROM    gis_poly_zip_temp p
                                          WHERE       p.geo_area_key = u.geo_area_key
                                                  AND p.state        = u.state_code
                                                  AND p.county_name  = u.county_name
                                                  AND p.city_name    = u.city_name
                                                  AND p.zip          = u.zip
                                                  AND p.zip9         = u.zip9
                                                  AND p.area_id      = u.area_id
                                         )
                ORDER BY zip9, area_id, county_name, city_name, id;


            CURSOR city IS
                SELECT d.*
                       , g.start_date
                       , g.virtual      -- crapp-2152
                FROM (  SELECT  DISTINCT
                                geo_poly_id     geo_polygon_id
                                , geo_area_key
                                , state_name
                                , state         state_code
                                , state_fips
                                , county_name
                                , county_fips
                                , city_name
                                , city_fips
                                , CASE WHEN city_rank = 1 THEN 'Y' ELSE NULL END default_city
                                , 0 multiple_states
                                , 0 multiple_counties
                                , 0 multiple_cities
                                , area_id
                        FROM    gis_poly_zip_temp
                        MINUS
                        SELECT  DISTINCT
                                p.id  geo_polygon_id
                                , p.geo_area_key
                                , u.state_name
                                , u.state_code
                                , u.state_fips
                                , u.county_name
                                , u.county_fips
                                , u.city_name
                                , u.city_fips
                                , CASE WHEN u.override_rank = 1 THEN 'Y' ELSE NULL END default_city
                                , 0 multiple_states
                                , 0 multiple_counties
                                , 0 multiple_cities
                                , area_id
                        FROM    geo_usps_lookup u
                                JOIN geo_polygons p ON u.geo_polygon_id = p.id
                        WHERE   u.state_code = stcode_i
                                AND u.zip IS NULL
                     ) d
                     JOIN geo_polygons g ON d.geo_polygon_id = g.id
                ORDER BY area_id
                        , county_name
                        , city_name;


            CURSOR zip5 IS
                SELECT  DISTINCT
                        t.geo_poly_id    geo_polygon_id
                        , t.geo_area_key
                        , t.state_name
                        , t.state        state_code
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.zip
                        , p.start_date
                        , t.default_zip4 default_zip
                        , 0 multiple_counties
                        , 0 multiple_cities
                        , 0 multiple_states
                        , t.area_id
                        , p.virtual     -- crapp-2152
                FROM    gis_poly_zip_temp t
                        JOIN geo_polygons p ON t.geo_poly_id = p.id
                WHERE   t.zip IS NOT NULL
                        AND t.state = stcode_i
                        AND t.geo_area_key IS NOT NULL
                        AND NOT EXISTS ( SELECT 1
                                         FROM   geo_usps_lookup u
                                         WHERE      u.state_code  = t.state
                                                AND u.county_name = t.county_name
                                                AND u.city_name   = t.city_name
                                                AND u.zip         = t.zip
                                                AND u.geo_polygon_id = t.geo_poly_id
                                                AND u.area_id     = t.area_id
                                                AND u.zip9 IS NULL
                                       )
                ORDER BY t.zip
                        , t.area_id
                        , t.geo_poly_id
                        , t.default_zip4;


            CURSOR zip9 IS
                SELECT  /*+index(d gis_defaultzips_temp_n1 index(p geo_polygons_pk)*/
                        d.geo_polygon_id
                        , d.geo_area_key
                        , d.state_name
                        , d.state_code
                        , d.state_fips
                        , d.county_name
                        , d.county_fips
                        , d.city_name
                        , d.city_fips
                        , d.zip9
                        , d.zipcode
                        , d.zip4
                        , d.default_zip4
                        , d.city_rank
                        , p.start_date
                        , 0 multiple_cities
                        , 0 multiple_counties
                        , 0 multiple_states
                        , area_id
                FROM    gis_defaultzips_temp d
                        JOIN geo_polygons p ON d.geo_polygon_id = p.id
                WHERE   p.next_rid IS NULL
                        AND NOT EXISTS ( SELECT /*+index(u geo_usps_lookup_i6)*/ 1
                                         FROM   geo_usps_lookup u
                                         WHERE      u.state_code  = d.state_code
                                                AND u.county_name = d.county_name
                                                AND u.city_name   = d.city_name
                                                AND u.zip9        = d.zip9
                                                AND u.area_id     = d.area_id
                                                AND u.geo_polygon_id = d.geo_polygon_id
                                       )
                ORDER BY d.zip9
                        , d.area_id
                        , d.default_zip4
                        , d.county_name
                        , d.city_name
                        , d.hierarchy_level_id
                        , d.geo_area_key
                        , d.city_rank;


            CURSOR nozip IS
                SELECT  DISTINCT
                        t.geo_poly_id    geo_polygon_id
                        , t.geo_area_key
                        , t.state_name
                        , t.state        state_code
                        , t.state_fips
                        , t.county_name
                        , t.county_fips
                        , t.city_name
                        , t.city_fips
                        , t.zip
                        , t.city_rank
                        , p.start_date
                        , t.default_zip4 default_zip
                        , 0 multiple_counties
                        , 0 multiple_cities
                        , 0 multiple_states
                        , t.area_id
                        , p.virtual     -- crapp-2152
                FROM    gis_poly_zip_temp t
                        JOIN geo_polygons p ON t.geo_poly_id = p.id
                WHERE   t.zip IS NULL
                        AND t.default_zip4 IS NULL
                        AND t.state = stcode_i
                        AND t.geo_area_key IS NOT NULL
                        AND p.next_rid IS NULL
                        AND NOT EXISTS ( SELECT /*+index(u geo_usps_lookup_i6)*/ 1
                                         FROM   geo_usps_lookup u
                                         WHERE      u.state_code  = t.state
                                                AND u.county_name = t.county_name
                                                AND u.city_name   = t.city_name
                                                AND u.area_id     = t.area_id
                                                AND u.geo_polygon_id = t.geo_poly_id
                                                AND u.zip IS NULL
                                       )
                ORDER BY t.zip
                        , t.area_id
                        , t.geo_poly_id;


            -- Added 08/14/15 --    -- 09/08/15 added index hints
            CURSOR invalid_defaults IS
                SELECT  DISTINCT *
                FROM    (
                        SELECT  /*+index(u geo_usps_lookup_i5) index(p geo_polygons_pk)*/
                                p.geo_area_key
                                , u.geo_polygon_id
                                , u.id
                                , u.county_name
                                , u.city_name
                                , u.zip
                                , u.attribute_id
                                , u.override_rank
                                , a.default_city
                                , u.area_id
                        FROM    geo_usps_lookup u
                                JOIN geo_polygons p ON u.geo_polygon_id = p.id
                                JOIN (
                                      SELECT DISTINCT
                                             state, county_name, city_name, default_city, area_id
                                      FROM   gis_indata_areas_temp t
                                      WHERE  state = stcode_i
                                      UNION  -- crapp-3485
                                      SELECT DISTINCT
                                             state, county_name, city_name, default_city, area_id
                                      FROM   gis_indata_areas_sup_temp
                                      WHERE  state = stcode_i
                                     ) a ON  u.state_code = a.state
                                         AND u.area_id = a.area_id
                        WHERE   u.state_code = stcode_i
                                AND u.zip IS NULL
                        )
                WHERE   default_city IS NULL
                        AND override_rank = 1
                ORDER BY area_id, county_name, city_name, geo_polygon_id;


            -- Added 08/14/15 --    -- 09/08/15 added index hints
            CURSOR valid_defaults IS
                SELECT  DISTINCT *
                FROM    (
                        SELECT  /*+index(u geo_usps_lookup_i5) index(p geo_polygons_pk)*/
                                p.geo_area_key
                                , u.geo_polygon_id
                                , u.id
                                , u.county_name
                                , u.city_name
                                , u.city_fips
                                , u.start_date
                                , u.zip
                                , u.attribute_id
                                , u.override_rank
                                , a.default_city
                                , u.area_id
                        FROM    geo_usps_lookup u
                                JOIN geo_polygons p ON u.geo_polygon_id = p.id
                                JOIN (
                                      SELECT DISTINCT
                                             state, county_name, city_name, default_city, area_id
                                      FROM   gis_indata_areas_temp t
                                      WHERE  state = stcode_i
                                      UNION  -- crapp-3485
                                      SELECT DISTINCT
                                             state, county_name, city_name, default_city, area_id
                                      FROM   gis_indata_areas_sup_temp
                                      WHERE  state = stcode_i
                                     ) a ON  u.state_code = a.state
                                         AND u.area_id = a.area_id
                        WHERE   u.state_code = stcode_i
                                AND u.zip IS NULL
                        )
                WHERE   default_city = 'Y'
                        AND NVL(override_rank, -1) <> 1
                ORDER BY area_id, county_name, city_name, geo_polygon_id;


            -- Added 08/26/15 -- crapp_2026
            CURSOR invalid_default_zip4s IS
                SELECT  DISTINCT *
                FROM    (
                        SELECT  /*+index(u geo_usps_lookup_i5) index(p geo_polygons_pk)*/
                                p.geo_area_key
                                , u.geo_polygon_id
                                , u.id
                                , u.county_name
                                , u.city_name
                                , u.zip9
                                , u.attribute_id
                                , u.override_rank
                                , a.default_zip4
                                , u.area_id
                        FROM    geo_usps_lookup u
                                JOIN geo_polygons p ON u.geo_polygon_id = p.id
                                JOIN (SELECT /*+index(t gis_indata_areas_temp_n3)*/ DISTINCT
                                             state, county_name, city_name, zip9, default_zip4, area_id
                                      FROM   gis_indata_areas_temp t
                                      WHERE  state = stcode_i
                                             AND zip9 IS NOT NULL   -- 09/08/15 added
                                     ) a ON  u.state_code = a.state
                                         AND u.area_id = a.area_id
                                         AND u.zip9 = a.zip9
                        WHERE   u.state_code = stcode_i
                                AND u.zip9 IS NOT NULL
                        )
                WHERE   default_zip4 IS NULL
                        AND override_rank = 1
                ORDER BY area_id, zip9, county_name, city_name, geo_polygon_id;


            -- Added 08/26/15 -- crapp_2026
            CURSOR valid_default_zip4s IS
                SELECT  DISTINCT *
                FROM    (
                        SELECT  /*+index(u geo_usps_lookup_i5) index(p geo_polygons_pk)*/
                                p.geo_area_key
                                , u.geo_polygon_id
                                , u.id
                                , u.county_name
                                , u.city_name
                                , u.city_fips
                                , u.start_date
                                , u.zip9
                                , u.attribute_id
                                , u.override_rank
                                , a.default_zip4
                                , u.area_id
                        FROM    geo_usps_lookup u
                                JOIN geo_polygons p ON u.geo_polygon_id = p.id
                                JOIN (SELECT /*+index(t gis_indata_areas_temp_n3)*/ DISTINCT
                                             state, county_name, city_name, zip9, default_zip4, area_id
                                      FROM   gis_indata_areas_temp t
                                      WHERE  state = stcode_i
                                             AND zip9 IS NOT NULL   -- 09/08/15 added
                                     ) a ON  u.state_code = a.state
                                         AND u.area_id = a.area_id
                                         AND u.zip9 = a.zip9
                        WHERE   u.state_code = stcode_i
                                AND u.zip9 IS NOT NULL
                        )
                WHERE   default_zip4 = 'Y'
                        AND NVL(override_rank, -1) <> 1
                ORDER BY area_id, zip9, county_name, city_name, geo_polygon_id;


            -- Updated 06/20/17 --
            CURSOR invalid_default_zips IS
                SELECT  DISTINCT *
                FROM    (
                        SELECT  /*+index(p geo_polygons_pk)*/
                                p.geo_area_key
                                , u.geo_polygon_id
                                , u.id
                                , u.county_name
                                , u.city_name
                                , u.zip
                                , u.attribute_id
                                , u.override_rank
                                , a.default_zip
                                , u.area_id
                        FROM    (
                                  SELECT state_code
                                         , geo_polygon_id
                                         , id
                                         , county_name
                                         , city_name
                                         , zip
                                         , attribute_id
                                         , override_rank
                                         , area_id
                                  FROM   geo_usps_lookup gu
                                  WHERE  state_code = stcode_i
                                         AND zip IS NOT NULL
                                         AND zip9 IS NULL
                                ) u
                                JOIN geo_polygons p ON (u.geo_polygon_id = p.id)
                                JOIN (SELECT /*+index(t gis_indata_areas_temp_n1)*/
                                             state, county_name, city_name, zip, default_zip, area_id
                                      FROM   gis_indata_areas_temp t
                                      WHERE  state = stcode_i
                                             AND zip IS NOT NULL
                                     ) a ON  u.state_code = a.state
                                         AND u.area_id = a.area_id
                                         AND u.zip = a.zip
                        )
                WHERE   default_zip IS NULL
                        AND override_rank = 1
                ORDER BY area_id, county_name, city_name, geo_polygon_id;


            -- Updated 06/20/17 --
            CURSOR valid_default_zips IS
                SELECT  DISTINCT *
                FROM    (
                        SELECT  /*+index(p geo_polygons_pk)*/
                                p.geo_area_key
                                , u.geo_polygon_id
                                , u.id
                                , u.county_name
                                , u.city_name
                                , u.city_fips
                                , u.start_date
                                , u.zip
                                , u.attribute_id
                                , u.override_rank
                                , a.default_zip
                                , u.area_id
                        FROM    (
                                  SELECT state_code
                                         , geo_polygon_id
                                         , id
                                         , county_name
                                         , city_name
                                         , city_fips
                                         , start_date
                                         , zip
                                         , attribute_id
                                         , override_rank
                                         , area_id
                                  FROM   geo_usps_lookup gu
                                  WHERE  state_code = stcode_i
                                         AND zip IS NOT NULL
                                         AND zip9 IS NULL
                                ) u
                                JOIN geo_polygons p ON (u.geo_polygon_id = p.id)
                                JOIN (SELECT /*+index(t gis_indata_areas_temp_n1)*/
                                             state, county_name, city_name, zip, default_zip, area_id
                                      FROM   gis_indata_areas_temp t
                                      WHERE  state = stcode_i
                                             AND zip IS NOT NULL
                                     ) a ON  u.state_code = a.state
                                         AND u.area_id = a.area_id
                                         AND u.zip = a.zip
                        )
                WHERE   default_zip = 'Y'
                        AND NVL(override_rank, -1) <> 1
                ORDER BY area_id, county_name, city_name, geo_polygon_id;

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_geo_polygon_usps', paction=>0, puser=>user_i);

            -- **************************************** --
            -- Determine USPS records that have changed --
            -- **************************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine USPS records that have changed - get_usps_staging', paction=>0, puser=>user_i);
                get_usps_staging (stcode_i, user_i, pID_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine USPS records that have changed - get_usps_staging', paction=>1, puser=>user_i);

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON hl.geo_area_category_id = g.id
                    JOIN hierarchy_definitions hd ON hl.hierarchy_definition_id = hd.id
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'District';

            -- ****************** --
            -- Remove Zip records --
            -- ****************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove Zip records - zips_removed', paction=>0, puser=>user_i);
            FOR z IN zips_removed LOOP
                -- Remove attribute record --
                DELETE FROM gis_usps_attributes
                WHERE  geo_polygon_usps_id = z.usps_id;

                -- Remove USPS record --
                DELETE FROM geo_polygon_usps
                WHERE  state_code = z.state_code
                       AND id = z.usps_id;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove Zip records - zips_removed', paction=>1, puser=>user_i);


            -- *********************** --
            -- Remove Null Zip records --
            -- *********************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove Null Zip records - null_zipsremoved', paction=>0, puser=>user_i);
            FOR nz IN null_zipsremoved LOOP
                -- Remove attribute record --
                DELETE FROM gis_usps_attributes
                WHERE  geo_polygon_usps_id = nz.usps_id;

                -- Remove USPS record --
                DELETE FROM geo_polygon_usps
                WHERE  state_code = nz.state_code
                       AND id = nz.usps_id;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove Null Zip records - null_zipsremoved', paction=>1, puser=>user_i);


            -- ******************* --
            -- Remove Zip9 records --
            -- ******************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove Zip9 records - zip9removed', paction=>0, puser=>user_i);
            FOR c IN zip9removed LOOP
                -- Remove attribute record --
                DELETE FROM gis_usps_attributes
                WHERE  geo_polygon_usps_id = c.usps_id;

                -- Remove USPS record --
                DELETE FROM geo_polygon_usps
                WHERE  state_code = c.state_code
                       AND id = c.usps_id;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove Zip9 records - zip9removed', paction=>1, puser=>user_i);


            -- ************************************* --
            -- Update USPS records that have changed --
            -- ************************************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh lookup and staging tables - P_ProcessLookup/get_usps_staging', paction=>0, puser=>user_i);
                gis_staging_lib.P_ProcessLookup(stcode_i);
                get_usps_staging (stcode_i, user_i, pID_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh lookup and staging tables - P_ProcessLookup/get_usps_staging', paction=>1, puser=>user_i);


            -- ******************************** --
            -- Import Default City USPS records --
            -- ******************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import default city USPS records - city', paction=>0, puser=>user_i);

            EXECUTE IMMEDIATE 'ALTER TABLE geo_polygon_usps MODIFY PARTITION LU_USPS_' ||stcode_i|| ' UNUSABLE LOCAL INDEXES'; -- 03/04/16 added
            EXECUTE IMMEDIATE 'ALTER INDEX geo_poly_usps_pk REBUILD PARTITION LU_USPS_' ||stcode_i|| '';    -- 03/04/16, needed for insert

            FOR u IN city LOOP <<city_loop>>

                INSERT INTO geo_polygon_usps
                (
                    geo_polygon_id
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , start_date
                    , entered_by
                    , status
                    , multiple_states
                    , multiple_counties
                    , multiple_cities
                    , area_id
                )
                VALUES
                    (
                        u.geo_polygon_id
                        , u.state_name
                        , u.state_code
                        , u.state_fips
                        , u.county_name
                        , u.county_fips
                        , u.city_name
                        , u.city_fips
                        , NVL(u.start_date, TO_DATE('01-Jan-2000'))
                        , user_i
                        , l_status
                        , u.multiple_states
                        , u.multiple_counties
                        , u.multiple_cities
                        , u.area_id
                    )
                RETURNING id, start_date INTO l_usps_pk, l_stdate;

                l_recs := l_recs + (SQL%ROWCOUNT);

                -- Add Attribute record indicating that City is the Default City
                IF u.default_city = 'Y' THEN
                    INSERT INTO gis_usps_attributes
                    (
                        geo_polygon_usps_id
                        , attribute_id
                        , VALUE
                        , override_rank
                        , start_date
                        , entered_by
                        , status
                    )
                    VALUES
                        (
                            l_usps_pk
                            , (SELECT id FROM additional_attributes WHERE name = 'Alias')
                            , CONCAT(RPAD(u.city_fips, 6, ' '), u.city_name) -- Pad City Fips to 6 spaces then add City Name
                            , 1                                              -- override_rank
                            , l_stdate
                            , user_i
                            , l_status
                        );
                END IF;
                COMMIT;
            END LOOP city_loop;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import default city USPS records - city', paction=>1, puser=>user_i);


            -- ************************ --
            -- Import Zip5 USPS records --
            -- ************************ --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import Zip5 USPS records - zip5', paction=>0, puser=>user_i);
            FOR u IN zip5 LOOP <<zip5_loop>>

                INSERT INTO geo_polygon_usps
                (
                    geo_polygon_id
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip
                    , start_date
                    , entered_by
                    , status
                    , multiple_cities
                    , multiple_states
                    , multiple_counties
                    , area_id
                )
                VALUES
                    (
                        u.geo_polygon_id
                        , u.state_name
                        , u.state_code
                        , u.state_fips
                        , u.county_name
                        , u.county_fips
                        , u.city_name
                        , u.city_fips
                        , u.zip
                        , NVL(u.start_date, TO_DATE('01-Jan-2000'))
                        , user_i
                        , l_status
                        , u.multiple_cities
                        , u.multiple_states
                        , u.multiple_counties
                        , u.area_id
                    )
                RETURNING id, start_date INTO l_usps_pk, l_stdate;
                l_recs := l_recs + (SQL%ROWCOUNT);


                -- Add Attributes indicating Default Zip
                IF u.default_zip = 'Y' THEN
                    INSERT INTO gis_usps_attributes
                    (
                        geo_polygon_usps_id
                        , attribute_id
                        , VALUE
                        , override_rank
                        , start_date
                        , entered_by
                        , status
                    )
                    VALUES
                        (
                            l_usps_pk
                            , (SELECT id FROM additional_attributes WHERE name = 'Alias')
                            , CONCAT(RPAD(u.city_fips, 6, ' '), u.city_name) -- Pad City Fips to 6 spaces then add City Name
                            , 1                                              -- override_rank
                            , l_stdate
                            , user_i
                            , l_status
                        );
                END IF; -- attributes
            END LOOP zip5_loop;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import Zip5 USPS records - zip5', paction=>1, puser=>user_i);


            -- ******************************* --
            -- Determine default zip9 values   --
            -- ******************************* --
            -- 06/12/15 moved to catch updates --
            -- ******************************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine default Zip9 records - get_defaultzip', paction=>0, puser=>user_i);
                get_defaultzip(stcode_i, user_i, pID_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine default Zip9 records - get_defaultzip', paction=>1, puser=>user_i);


            -- ************************ --
            -- Import Zip9 USPS records --
            -- ************************ --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import Zip9 USPS records - zip9', paction=>0, puser=>user_i);
            FOR u IN zip9 LOOP <<zip9_loop>>

                INSERT INTO geo_polygon_usps
                (
                    geo_polygon_id
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , zip
                    , plus4_range
                    , start_date
                    , entered_by
                    , status
                    , multiple_cities
                    , multiple_states
                    , multiple_counties
                    , area_id
                )
                VALUES
                    (
                        u.geo_polygon_id
                        , u.state_name
                        , u.state_code
                        , u.state_fips
                        , u.county_name
                        , u.county_fips
                        , u.city_name
                        , u.city_fips
                        , u.zipcode
                        , u.zip4
                        , NVL(u.start_date, TO_DATE('01-Jan-2000'))
                        , user_i
                        , l_status
                        , u.multiple_cities
                        , u.multiple_states
                        , u.multiple_counties
                        , u.area_id
                    )
                RETURNING id, start_date INTO l_usps_pk, l_stdate;
                l_recs := l_recs + (SQL%ROWCOUNT);

                -- Add Attributes indicating Default Zip4
                IF u.default_zip4 = 'Y' THEN
                    INSERT INTO gis_usps_attributes
                    (
                        geo_polygon_usps_id
                        , attribute_id
                        , VALUE
                        , override_rank
                        , start_date
                        , entered_by
                        , status
                    )
                    VALUES
                        (
                            l_usps_pk
                            , (SELECT id FROM additional_attributes WHERE name = 'Alias')
                            , CONCAT(RPAD(u.city_fips, 6, ' '), u.city_name) -- Pad City Fips to 6 spaces then add City Name
                            , 1                                              -- override_rank
                            , l_stdate
                            , user_i
                            , l_status
                        );
                END IF;

                COMMIT;
            END LOOP zip9_loop;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import Zip9 USPS records - zip9', paction=>1, puser=>user_i);


            -- ************************** --
            -- Import No Zip USPS records --
            -- ************************** --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import No Zip USPS records - nozip', paction=>0, puser=>user_i);
            FOR u IN nozip LOOP <<nozip_loop>>

                INSERT INTO geo_polygon_usps
                (
                    geo_polygon_id
                    , state_name
                    , state_code
                    , state_fips
                    , county_name
                    , county_fips
                    , city_name
                    , city_fips
                    , start_date
                    , entered_by
                    , status
                    , multiple_states
                    , multiple_counties
                    , multiple_cities
                    , area_id
                )
                VALUES
                    (
                        u.geo_polygon_id
                        , u.state_name
                        , u.state_code
                        , u.state_fips
                        , u.county_name
                        , u.county_fips
                        , u.city_name
                        , u.city_fips
                        , NVL(u.start_date, TO_DATE('01-Jan-2000'))
                        , user_i
                        , l_status
                        , u.multiple_states
                        , u.multiple_counties
                        , u.multiple_cities
                        , u.area_id
                    );

                l_recs := l_recs + (SQL%ROWCOUNT);
                COMMIT;
            END LOOP nozip_loop;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Import No Zip USPS records - nozip', paction=>1, puser=>user_i);

            -- Rebuild Indexes -- 03/04/16
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and refresh Stats - geo_polygon_usps', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX geo_poly_usps_area_ix  REBUILD PARTITION LU_USPS_' ||stcode_i|| '';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_poly_usps_pk       REBUILD PARTITION LU_USPS_' ||stcode_i|| '';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_poly_usps_state_ix REBUILD PARTITION LU_USPS_' ||stcode_i|| '';
            EXECUTE IMMEDIATE 'ALTER INDEX geo_poly_usps_zip_ix   REBUILD PARTITION LU_USPS_' ||stcode_i|| '';

            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_polygon_usps', cascade => TRUE);
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_attributes', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and refresh Stats - geo_polygon_usps', paction=>1, puser=>user_i);


            -- ******************************************* --
            -- Populate Geo_USPS_Lookup table with changes --   -- 03/19/15 crapp-1418
            -- ******************************************* --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS lookup table - P_ProcessLookup', paction=>0, puser=>user_i);
                gis_staging_lib.P_ProcessLookup( stcode_i );
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS lookup table - P_ProcessLookup', paction=>1, puser=>user_i);


            -- *********************** --
            -- Process Default Changes --
            -- *********************** --
            IF type_i = 'U' THEN    -- Only process default changes if import is an Update -- 09/09/15
                l_ccnt := 0;

                -- Remove Invalid Attribute Records --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default City changes - invalid_defaults', paction=>0, puser=>user_i);
                FOR i IN invalid_defaults LOOP
                    DELETE FROM gis_usps_attributes
                    WHERE  geo_polygon_usps_id = i.id
                           AND override_rank = i.override_rank;

                    l_ccnt := l_ccnt + 1;
                END LOOP;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default City changes - invalid_defaults', paction=>1, puser=>user_i);


                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default City changes - valid_defaults', paction=>0, puser=>user_i);
                FOR v IN valid_defaults LOOP
                    UPDATE gis_usps_attributes
                        SET override_rank = 1
                    WHERE   geo_polygon_usps_id = v.id;

                    -- Add Attributes indicating Default City
                    IF v.default_city = 'Y' AND v.attribute_id IS NULL THEN
                        INSERT INTO gis_usps_attributes
                        (
                            geo_polygon_usps_id
                            , attribute_id
                            , VALUE
                            , override_rank
                            , start_date
                            , entered_by
                            , status
                        )
                        VALUES
                            (
                                v.id
                                , (SELECT id FROM additional_attributes WHERE name = 'Alias')
                                , CONCAT(RPAD(v.city_fips, 6, ' '), v.city_name) -- Pad City Fips to 6 spaces then add City Name
                                , 1                                              -- override_rank
                                , v.start_date
                                , user_i
                                , l_status
                            );
                    END IF;

                    l_ccnt := l_ccnt + 1;
                END LOOP;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default City changes - valid_defaults', paction=>1, puser=>user_i);


                -- **************************** --
                -- Process Default Zip4 Changes --  -- 08/26/15 crapp_2026
                -- **************************** --

                -- Remove Invalid Attribute Records --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip4 changes - invalid_default_zip4s', paction=>0, puser=>user_i);
                FOR z IN invalid_default_zip4s LOOP
                    UPDATE gis_usps_attributes
                        SET override_rank = 0
                    WHERE   geo_polygon_usps_id = z.id;

                    l_ccnt := l_ccnt + 1;
                END LOOP;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip4 changes - invalid_default_zip4s', paction=>1, puser=>user_i);


                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip4 changes - valid_default_zip4s', paction=>0, puser=>user_i);
                FOR z IN valid_default_zip4s LOOP
                    UPDATE gis_usps_attributes
                        SET override_rank = 1
                    WHERE   geo_polygon_usps_id = z.id;

                    -- Add Attributes indicating Default Zip4
                    IF z.default_zip4 = 'Y' AND z.attribute_id IS NULL THEN
                        INSERT INTO gis_usps_attributes
                        (
                            geo_polygon_usps_id
                            , attribute_id
                            , VALUE
                            , override_rank
                            , start_date
                            , entered_by
                            , status
                        )
                        VALUES
                            (
                                z.id
                                , (SELECT id FROM additional_attributes WHERE name = 'Alias')
                                , CONCAT(RPAD(z.city_fips, 6, ' '), z.city_name) -- Pad City Fips to 6 spaces then add City Name
                                , 1                                              -- override_rank
                                , z.start_date
                                , user_i
                                , l_status
                            );
                    END IF;

                    l_ccnt := l_ccnt + 1;
                END LOOP;
                COMMIT;
                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_attributes', cascade => TRUE);
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip4 changes - valid_default_zip4s', paction=>1, puser=>user_i);


                -- **************************** --
                -- Process Default Zip5 Changes --  -- 10/28/15 crapp-2026
                -- **************************** --

                -- Remove Invalid Attribute Records --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip changes - invalid_default_zips', paction=>0, puser=>user_i);
                FOR z IN invalid_default_zips LOOP
                    UPDATE gis_usps_attributes
                        SET override_rank = 0
                    WHERE   geo_polygon_usps_id = z.id;

                    l_ccnt := l_ccnt + 1;
                END LOOP;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip changes - invalid_default_zips', paction=>1, puser=>user_i);


                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip changes - valid_default_zips', paction=>0, puser=>user_i);
                FOR z IN valid_default_zips LOOP
                    UPDATE gis_usps_attributes
                        SET override_rank = 1
                    WHERE   geo_polygon_usps_id = z.id;

                    -- Add Attributes indicating Default Zip4
                    IF z.default_zip = 'Y' AND z.attribute_id IS NULL THEN
                        INSERT INTO gis_usps_attributes
                        (
                            geo_polygon_usps_id
                            , attribute_id
                            , VALUE
                            , override_rank
                            , start_date
                            , entered_by
                            , status
                        )
                        VALUES
                            (
                                z.id
                                , (SELECT id FROM additional_attributes WHERE name = 'Alias')
                                , CONCAT(RPAD(z.city_fips, 6, ' '), z.city_name) -- Pad City Fips to 6 spaces then add City Name
                                , 1                                              -- override_rank
                                , z.start_date
                                , user_i
                                , l_status
                            );
                    END IF;

                    l_ccnt := l_ccnt + 1;
                END LOOP;
                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_usps_attributes', cascade => TRUE);
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Process default Zip changes - valid_default_zips', paction=>1, puser=>user_i);


                IF l_ccnt > 0 THEN
                    gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS lookup table - P_ProcessLookup', paction=>0, puser=>user_i);
                        gis_staging_lib.P_ProcessLookup( stcode_i );
                    gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS lookup table - P_ProcessLookup', paction=>1, puser=>user_i);
                END IF;
            END IF; -- type_i

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_geo_polygon_usps', paction=>1, puser=>user_i);
            RETURN l_recs;
        END update_geo_polygon_usps;



    -- *************************************** --
    -- Load Unique Areas for each Zip by State --
    -- *************************************** --
    PROCEDURE create_unique_areas (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER)
    IS
            l_status NUMBER := 0;
            l_stdate DATE   := SYSDATE;

            CURSOR ua_taxids IS
                SELECT  DISTINCT
                        t.state state_code
                        , t.unique_area
                        , t.area_id
                        , t.taxid
                        , a.id  ua_id
                        , a.rid
                        , a.nkid
                FROM    gis_indata_areas_temp t
                        JOIN geo_unique_areas a ON t.area_id = a.area_id
                WHERE   t.taxid IS NOT NULL
                        AND a.next_rid IS NULL
                        AND NOT EXISTS (SELECT 1
                                        FROM   geo_unique_area_attributes aa
                                        WHERE  aa.geo_unique_area_id = a.id
                                               AND aa.attribute_id = (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                                       )
                -- 01/06/16 -- crapp-2152
                UNION
                SELECT  DISTINCT
                        t.state state_code
                        , t.unique_area
                        , t.area_id
                        , t.taxid
                        , a.id  ua_id
                        , a.rid
                        , a.nkid
                FROM    gis_indata_areas_sup_temp t
                        JOIN geo_unique_areas a ON t.area_id = a.area_id
                WHERE   t.taxid IS NOT NULL
                        AND a.next_rid IS NULL
                        AND NOT EXISTS (SELECT 1
                                        FROM   geo_unique_area_attributes aa
                                        WHERE  aa.geo_unique_area_id = a.id
                                               AND aa.attribute_id = (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                                       )
                ORDER BY unique_area;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'create_unique_areas', paction=>0, puser=>user_i);

            -- Refresh the MV Staging Table -- crapp-1418
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS MV stage table - P_ProcessMT', paction=>0, puser=>user_i);
                gis_staging_lib.P_ProcessMT( stcode_i );
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS MV stage table - P_ProcessMT', paction=>1, puser=>user_i);

            -- Refresh the Unique Area Materialized View --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh Materialized View - vgeo_unique_areas2', paction=>0, puser=>user_i);
                gis_staging_lib.P_RefreshMV(stcode_i);  -- crapp-2794
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh Materialized View - vgeo_unique_areas2', paction=>1, puser=>user_i);


            -- Determine latest start date of unique area boundaries - crapp-2145
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine latest start date of unique area boundaries - gis_poly_areas_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

            INSERT INTO gis_poly_areas_temp
                (state_code, area_id, start_date, end_date)
                SELECT  state_code
                        , area_id
                        , MAX(start_date) start_date
                        , MIN(end_date) end_date
                FROM   (
                        SELECT  DISTINCT
                                a.state_code
                                , a.area_id
                                , a.geo_area_key
                                , a.rid
                                , a.nkid
                                , p.start_date
                                , p.end_date
                        FROM    geo_usps_mv_staging a
                                JOIN geo_polygons p ON (a.nkid = p.nkid
                                                        AND p.next_rid IS NULL)
                        WHERE   a.state_code = stcode_i
                        )
                GROUP BY state_code, area_id;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine latest start date of unique area boundaries - gis_poly_areas_temp', paction=>1, puser=>user_i);


            -- Create Unique Areas --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create unique areas - geo_unique_areas', paction=>0, puser=>user_i);
            MERGE /*+index (t geo_unique_areas_un)*/ INTO geo_unique_areas t
                USING ( SELECT DISTINCT
                               a.state_code
                               , a.area_id
                               , s.start_date   -- using latest start date of Unique Area Polygons - crapp-2145
                               , user_i entered_by
                               , l_status status
                        FROM   vgeo_unique_areas2 a
                               JOIN gis_poly_areas_temp s ON (a.area_id = s.area_id)
                        WHERE  a.state_code = stcode_i
                      ) s ON ( t.area_id = s.area_id )
                      WHEN NOT MATCHED THEN INSERT
                        (t.area_id, t.start_date, t.entered_by, t.status)
                        VALUES (s.area_id, s.start_date, s.entered_by, s.status);

            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create unique areas - geo_unique_areas', paction=>1, puser=>user_i);


            -- Build temp tables for Unique Area / Polygon associations --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build temp tables for UA/Polygon associations - gis_unique_areas_temp/gis_poly_areas_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_unique_areas_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

            INSERT INTO gis_unique_areas_temp
                (state_name, county_name, city_name, area_id, unique_area)
                SELECT DISTINCT
                       state_name
                       , county_name
                       , city_name
                       , area_id
                       , UPPER(unique_area) unique_area -- 01/20/16
                FROM   vgeo_unique_areas2
                WHERE  state_code = stcode_i;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_unique_areas_temp', cascade => TRUE);

            MERGE INTO gis_poly_areas_temp t
                USING ( WITH area_ids AS
                             ( SELECT /*+index (g geo_unique_areas_un)*/
                                      g.id
                                      , a.unique_area
                               FROM   geo_unique_areas g
                                      JOIN gis_unique_areas_temp a ON (g.area_id = a.area_id)
                             )
                             SELECT  /*+index (p geo_polygons_n2)*/
                                     DISTINCT
                                     p.id       geo_polygon_id
                                     , ua.id    unique_area_id
                                     , user_i   entered_by
                                     , l_status status
                             FROM    geo_polygons p
                                     JOIN area_ids ua ON (ua.unique_area LIKE ('%' || UPPER(p.geo_area_key) || '%'))
                             WHERE   SUBSTR(p.geo_area_key, 1, 2) = stcode_i
                      ) s ON (      t.id = s.geo_polygon_id
                                AND t.unique_area_id = s.unique_area_id
                             )
                      WHEN NOT MATCHED THEN INSERT
                          (t.id, t.unique_area_id, t.entered_by, t.status)
                      VALUES
                          (s.geo_polygon_id, s.unique_area_id, s.entered_by, s.status);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build temp tables for UA/Polygon associations - gis_unique_areas_temp/gis_poly_areas_temp', paction=>1, puser=>user_i);


            -- Create association between Unique Area and Polygons --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create UA/Polygon associations - geo_unique_area_polygons', paction=>0, puser=>user_i);
            MERGE /*+index (t geo_unique_area_polygons_n2) index(s gis_poly_areas_temp_n1)*/ INTO geo_unique_area_polygons t
                USING ( SELECT  DISTINCT
                                id  geo_polygon_id
                                , unique_area_id
                                , entered_by
                                , status
                        FROM    gis_poly_areas_temp
                      ) s ON (      t.geo_polygon_id = s.geo_polygon_id
                                AND t.unique_area_id = s.unique_area_id
                             )
                      WHEN NOT MATCHED THEN INSERT
                          (t.geo_polygon_id, t.unique_area_id, t.entered_by, t.status)
                      VALUES
                          (s.geo_polygon_id, s.unique_area_id, s.entered_by, s.status);

            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create UA/Polygon associations - geo_unique_area_polygons', paction=>1, puser=>user_i);


            -- Create TAX_ID Attribute --   08/05/15 - crapp-1003
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create TAX_ID UA attributes - geo_unique_area_attributes', paction=>0, puser=>user_i);
            FOR i IN ua_taxids LOOP
                INSERT INTO geo_unique_area_attributes
                (
                    geo_unique_area_id
                    , attribute_id
                    , VALUE
                    , start_date
                    , entered_by
                    , status
                    , rid
                )
                VALUES
                    (
                        i.ua_id
                        , (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                        , i.taxid
                        , l_stdate
                        , user_i
                        , l_status
                        , i.rid
                    );
            END LOOP;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_unique_area_attributes', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create TAX_ID UA attributes - geo_unique_area_attributes', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'create_unique_areas', paction=>1, puser=>user_i);
        END create_unique_areas;



    -- ***************************************** --
    -- Update Unique Areas for each Zip by State --
    -- ***************************************** --
    PROCEDURE update_unique_areas (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) -- crapp-3074
    IS
            l_status    NUMBER := 0;
            l_recs      NUMBER := 0;
            l_zip9s     NUMBER := 0;    -- crapp-2364
            l_date      DATE   := SYSDATE;

            TYPE record_t IS RECORD
            (
              id         geo_unique_areas.id%TYPE,
              area_id    geo_unique_areas.area_id%TYPE,
              curr_date  geo_unique_areas.end_date%TYPE,
              new_date   geo_unique_areas.end_date%TYPE
            );

            TYPE arr_t IS TABLE OF record_t;
            arr arr_t;

            CURSOR taxids_removed IS
                SELECT  ta.*
                        , gua.start_date
                        , gua.end_date
                        , CASE WHEN TRUNC(gua.start_date) > TRUNC(SYSDATE)-1 THEN gua.start_date
                               ELSE TRUNC(SYSDATE)-1
                          END new_end_date
                FROM    (
                        SELECT  ua.state_code
                                --, ua.unique_area        -- 01/19/16, removed to eliminate duplicate TaxIDs with CASE Sensitive Unique Areas
                                , a.area_id
                                , aa.VALUE taxid
                                , a.id ua_id
                                , a.rid
                                , a.nkid
                        FROM    vunique_area_attributes aa
                                JOIN geo_unique_areas a ON (aa.unique_area_nkid = a.nkid)
                                JOIN (  --vunique_areas     -- 01/19/16, expanded out view to allow for hints and state_code to increase performance
                                     SELECT /*+index(u geo_unique_area_polygons_n1) index(gua geo_unique_areas_pk)*/
                                            DISTINCT
                                            vgua.unique_area
                                            , gua.id
                                            , gua.rid
                                            , gua.nkid
                                            , gua.next_rid
                                            , vgua.state_code
                                     FROM   geo_unique_area_polygons u
                                            JOIN geo_unique_areas gua ON (u.unique_area_id = gua.id)
                                            JOIN (SELECT DISTINCT
                                                         state_code
                                                         , area_id
                                                         , unique_area
                                                  FROM   vgeo_unique_areas2
                                                  WHERE  state_code = stcode_i
                                                 ) vgua ON (gua.area_id = vgua.area_id)
                                     ) ua ON (a.nkid = ua.nkid)
                        WHERE   aa.attribute_id = (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                                AND aa.end_date IS NULL
                        MINUS
                            (
                            SELECT  DISTINCT
                                    t.state state_code
                                    --, t.unique_area     -- 01/19/16, removed to eliminate duplicate TaxIDs with CASE Sensitive Unique Areas
                                    , t.area_id
                                    , t.taxid
                                    , a.id  ua_id
                                    , a.rid
                                    , a.nkid
                            FROM    gis_indata_areas_temp t
                                    JOIN geo_unique_areas a ON t.area_id = a.area_id
                            WHERE   t.taxid IS NOT NULL
                                    AND a.next_rid IS NULL
                            -- 01/06/16 -- crapp-2152
                            UNION
                            SELECT  DISTINCT
                                    t.state state_code
                                    --, t.unique_area     -- 01/19/16, removed to eliminate duplicate TaxIDs with CASE Sensitive Unique Areas
                                    , t.area_id
                                    , t.taxid
                                    , a.id  ua_id
                                    , a.rid
                                    , a.nkid
                            FROM    gis_indata_areas_sup_temp t
                                    JOIN geo_unique_areas a ON t.area_id = a.area_id
                            WHERE   t.taxid IS NOT NULL
                                    AND a.next_rid IS NULL
                            )
                        ) ta
                        JOIN geo_unique_areas gua ON (ta.ua_id = gua.id);

            CURSOR ua_taxids IS
                SELECT  DISTINCT
                        t.state state_code
                        , UPPER(t.unique_area) unique_area
                        , t.area_id
                        , t.taxid
                        , a.id  ua_id
                        , a.rid
                        , a.nkid
                FROM    gis_indata_areas_temp t
                        JOIN geo_unique_areas a ON (t.area_id = a.area_id)
                WHERE   t.taxid IS NOT NULL
                        AND a.next_rid IS NULL
                        AND NOT EXISTS (SELECT 1
                                        FROM   geo_unique_area_attributes aa
                                        WHERE  aa.geo_unique_area_id = a.id
                                               AND aa.value = t.taxid
                                               AND aa.attribute_id = (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                                               AND aa.end_date IS NULL
                                       )
                -- 01/06/16 -- crapp-2152
                UNION
                SELECT  DISTINCT
                        t.state state_code
                        , UPPER(t.unique_area) unique_area
                        , t.area_id
                        , t.taxid
                        , a.id  ua_id
                        , a.rid
                        , a.nkid
                FROM    gis_indata_areas_sup_temp t
                        JOIN geo_unique_areas a ON (t.area_id = a.area_id)
                WHERE   t.taxid IS NOT NULL
                        AND a.next_rid IS NULL
                        AND NOT EXISTS (SELECT 1
                                        FROM   geo_unique_area_attributes aa
                                        WHERE  aa.geo_unique_area_id = a.id
                                               AND aa.value = t.taxid
                                               AND aa.attribute_id = (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                                               AND aa.end_date IS NULL
                                       )
                ORDER BY unique_area;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_unique_areas', paction=>0, puser=>user_i);

            -- Determine Unique Areas based on current GIS updates --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine unique areas based on current GIS data - gis_poly_areas_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';
            INSERT INTO gis_poly_areas_temp
                (zip, zip9, state_code, state_name, county_name, city_name, unique_area, area_id)
                SELECT DISTINCT
                       zip, zip9, state, state_name, county_name, city_name, unique_area, area_id
                FROM   gis_indata_areas_temp
                -- 01/06/16 -- crapp-2152
                UNION
                SELECT DISTINCT
                       zip, zip9, state, state_name, county_name, city_name, unique_area, area_id
                FROM   gis_indata_areas_sup_temp
                ORDER BY zip9, unique_area;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_areas_temp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine unique areas based on current GIS data - gis_poly_areas_temp', paction=>1, puser=>user_i);

            -- Log Unique Area additions --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Log New unique areas (ADD) - geo_update_area_log', paction=>0, puser=>user_i);
            INSERT INTO geo_update_area_log
                (state_code, area_id, update_type, entered_by, entered_date, status)   -- removed unique_area, basing on area_id
              SELECT DISTINCT
                     state_code, area_id, 'ADD', user_i, l_date, l_status
              FROM   gis_poly_areas_temp
              MINUS
              SELECT DISTINCT
                     state_code, area_id, 'ADD', user_i, l_date, l_status
              FROM   vgeo_unique_areas2
              WHERE  state_code = stcode_i;

            l_recs := l_recs + (SQL%ROWCOUNT);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Log New unique areas (ADD) - geo_update_area_log', paction=>1, puser=>user_i);


            -- Log Unique Area removals --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Log unique areas removed (DELETE) - geo_update_area_log', paction=>0, puser=>user_i);
            INSERT INTO geo_update_area_log
                (state_code, area_id, update_type, entered_by, entered_date, status)   -- removed unique_area, basing on area_id
                SELECT DISTINCT
                       state_code, area_id, 'DELETE', user_i, l_date, l_status
                FROM   vgeo_unique_areas2
                WHERE  state_code = stcode_i
                MINUS
                SELECT DISTINCT
                       state_code, area_id, 'DELETE', user_i, l_date, l_status
                FROM   gis_poly_areas_temp;

            l_recs := l_recs + (SQL%ROWCOUNT);
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_update_area_log', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Log unique areas removed (DELETE) - geo_update_area_log', paction=>1, puser=>user_i);


            SELECT COUNT(*)
            INTO l_zip9s
            FROM  gis_defaultzips_temp;

            -- If any changes to Zip9/Unique_Areas, then refresh the Materialized View -- 02/22/16 crapp-2364 (Zip9 changes)
            IF l_recs > 0 OR l_zip9s > 0 THEN
                -- Refresh the MV Staging Table -- crapp-1418
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS MV stage table - P_ProcessMT', paction=>0, puser=>user_i);
                    gis_staging_lib.P_ProcessMT( stcode_i );
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh USPS MV stage table - P_ProcessMT', paction=>1, puser=>user_i);

                -- Refresh the Unique Area Materialized View --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh Materialized View - vgeo_unique_areas2', paction=>0, puser=>user_i);
                    gis_staging_lib.P_RefreshMV(stcode_i);  -- crapp-2794
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Refresh Materialized View - vgeo_unique_areas2', paction=>1, puser=>user_i);
            END IF;


            -- If any changes in Unique_Areas, then update the area tables --
            IF l_recs > 0 THEN

                -- Determine latest start date of unique area boundaries - crapp-2145
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine latest start date of unique area boundaries - gis_poly_areas_temp', paction=>0, puser=>user_i);
                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

                INSERT INTO gis_poly_areas_temp
                    (state_code, area_id, start_date)
                    SELECT  state_code
                            , area_id
                            , MAX(start_date) start_date
                    FROM   (
                            SELECT  DISTINCT
                                    a.state_code
                                    , a.area_id
                                    , a.geo_area_key
                                    , a.rid
                                    , a.nkid
                                    , p.start_date
                            FROM    geo_usps_mv_staging a
                                    JOIN geo_polygons p ON (a.nkid = p.nkid
                                                            AND p.next_rid IS NULL)
                            WHERE   a.state_code = stcode_i
                            )
                    GROUP BY state_code, area_id;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine latest start date of unique area boundaries - gis_poly_areas_temp', paction=>1, puser=>user_i);


                -- Add Unique Areas --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Add new unique areas - geo_unique_areas', paction=>0, puser=>user_i);
                MERGE INTO geo_unique_areas t
                    USING ( SELECT DISTINCT
                                   area_id
                                   , start_date   -- using latest start date of Unique Area Polygons - crapp-2145
                                   , user_i   entered_by
                                   , l_status status
                            FROM   ( SELECT DISTINCT
                                            l.state_code
                                            , l.unique_area
                                            , l.area_id
                                            , p.start_date
                                     FROM   geo_update_area_log l
                                            JOIN gis_poly_areas_temp p ON (l.area_id = p.area_id)
                                     WHERE  l.state_code = stcode_i
                                            AND l.update_type = 'ADD'
                                            AND l.entered_date = l_date
                                   ) a
                          ) s ON ( t.area_id = s.area_id )
                          WHEN NOT MATCHED THEN INSERT
                            (t.area_id, t.start_date, t.entered_by, t.status)
                            VALUES (s.area_id, s.start_date, s.entered_by, s.status);

                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Add new unique areas - geo_unique_areas', paction=>1, puser=>user_i);


                -- Determine earliest end date of unique area boundaries - crapp-2145
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine earliest end date of unique area boundaries - gis_poly_areas_temp', paction=>0, puser=>user_i);
                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

                INSERT INTO gis_poly_areas_temp
                    (state_code, unique_area, area_id, id, geo_area_key, start_date, end_date)
                    SELECT  DISTINCT
                            l.state_code
                            , l.unique_area
                            , l.area_id
                            , a.id
                            , p.geo_area_key
                            , p.start_date
                            , p.end_date
                    FROM    geo_update_area_log l
                            JOIN geo_unique_areas a ON (l.area_id = a.area_id)
                            JOIN geo_unique_area_polygons uap ON (a.id = uap.unique_area_id)
                            JOIN geo_polygons p ON (uap.geo_polygon_id = p.id)
                            LEFT JOIN (SELECT DISTINCT state_code, area_id
                                       FROM   vgeo_unique_areas2
                                       WHERE  state_code = stcode_i
                                      ) va ON (a.area_id = va.area_id)
                    WHERE   l.state_code = stcode_i
                            AND l.update_type = 'DELETE'
                            AND l.area_id IS NOT NULL
                            AND va.state_code IS NULL -- Exclude valid areas
                    ORDER BY l.area_id, a.id;

                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine earliest end date of unique area boundaries - gis_poly_areas_temp', paction=>1, puser=>user_i);


                -- Update the End_Date for Unique_Areas that have a polygon that is no longer valid --
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Set End_Date of removed Unique Areas - geo_unique_areas', paction=>0, puser=>user_i);
                SELECT  a.id
                        , a.area_id
                        , a.end_date curr_date
                        , MIN(p.end_date) new_date
                BULK COLLECT INTO arr
                FROM    geo_unique_areas a
                        JOIN gis_poly_areas_temp p ON a.area_id = p.area_id
                GROUP BY a.id
                        , a.area_id
                        , a.end_date
                HAVING MIN(p.end_date) IS NOT NULL
                ORDER BY a.area_id;

                FORALL i IN 1..arr.COUNT
                    UPDATE geo_unique_areas
                        SET end_date = arr(i).new_date
                    WHERE  id = arr(i).id
                           AND area_id = arr(i).area_id;

                COMMIT;


                -- Update the End Date for Unique Areas where all polygons are still valid --
                SELECT  a.id
                        , a.area_id
                        , a.end_date curr_date
                        , TRUNC(SYSDATE) new_date
                BULK COLLECT INTO arr
                FROM    geo_unique_areas a
                        JOIN gis_poly_areas_temp p ON a.area_id = p.area_id
                GROUP BY a.id
                        , a.area_id
                        , a.end_date
                HAVING MIN(p.end_date) IS NULL
                ORDER BY a.area_id;

                FORALL i IN 1..arr.COUNT
                    UPDATE geo_unique_areas
                        SET end_date = arr(i).new_date
                    WHERE  id = arr(i).id
                           AND area_id = arr(i).area_id;

                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Set End_Date of removed Unique Areas - geo_unique_areas', paction=>1, puser=>user_i);

                -- Reset end date of unique area Added back by GIS - crapp-2247
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine earliest end date of boundaries for unique areas Added - gis_poly_areas_temp', paction=>0, puser=>user_i);
                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

                INSERT INTO gis_poly_areas_temp
                    (state_code, unique_area, area_id, id, geo_area_key, start_date, end_date)
                    SELECT  DISTINCT
                            l.state_code
                            , l.unique_area
                            , l.area_id
                            , a.id
                            , p.geo_area_key
                            , p.start_date
                            , p.end_date
                    FROM    geo_update_area_log l
                            JOIN geo_unique_areas a ON (l.area_id = a.area_id)
                            JOIN geo_unique_area_polygons uap ON (a.id = uap.unique_area_id)
                            JOIN geo_polygons p ON (uap.geo_polygon_id = p.id)
                    WHERE   l.state_code = stcode_i
                            AND l.update_type = 'ADD'
                            AND l.area_id IS NOT NULL
                            AND l.entered_date = l_date
                    ORDER BY l.area_id, a.id;

                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine earliest end date of boundaries for unique areas Added - gis_poly_areas_temp', paction=>1, puser=>user_i);

                -- Update the End Date for Unique Areas that were Added back from GIS -- crapp-2247
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Clear End_Date of Added Unique Areas - geo_unique_areas', paction=>0, puser=>user_i);
                SELECT *
                BULK COLLECT INTO arr
                FROM   (
                        SELECT  a.id
                                , a.area_id
                                , a.end_date curr_date
                                , MIN(p.end_date) new_date
                        FROM    geo_unique_areas a
                                JOIN gis_poly_areas_temp p ON a.area_id = p.area_id
                        GROUP BY a.id
                                , a.area_id
                                , a.end_date
                       )
                WHERE  curr_date <> NVL(new_date, TO_DATE('01-Jan-1900'))
                ORDER BY area_id;

                FORALL i IN 1..arr.COUNT
                    UPDATE geo_unique_areas
                        SET end_date = arr(i).new_date
                    WHERE  id = arr(i).id
                           AND area_id = arr(i).area_id;

                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Clear End_Date of Added Unique Areas - geo_unique_areas', paction=>1, puser=>user_i);
            END IF;


            -- CRAPP-3074 - moved boundary association section to always process
            -- Build temp tables for Unique Area / Polygon associations --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build temp tables for UA/Polygon associations - gis_unique_areas_temp/gis_poly_areas_temp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_unique_areas_temp DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

            INSERT INTO gis_unique_areas_temp
                (state_name, county_name, city_name, area_id, unique_area)
                SELECT DISTINCT
                       gua.state_name
                       , gua.county_name
                       , gua.city_name
                       , gua.area_id
                       , UPPER(gua.unique_area) unique_area -- 01/20/16
                FROM   vgeo_unique_areas2 gua
                WHERE  gua.state_code = stcode_i;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_unique_areas_temp', cascade => TRUE);

            MERGE INTO gis_poly_areas_temp t
                USING ( WITH area_ids AS
                             ( SELECT /*+index(g geo_unique_areas_un)*/
                                      g.id
                                      , a.unique_area
                                      , a.area_id
                               FROM   geo_unique_areas g
                                      JOIN gis_unique_areas_temp a ON (g.area_id = a.area_id)
                             )
                             SELECT  /*+index(p geo_polygons_n2)*/
                                     DISTINCT
                                     p.id  geo_polygon_id
                                     , p.geo_area_key
                                     , ua.id  unique_area_id
                                     , ua.area_id
                                     , user_i entered_by
                                     , l_status status
                             FROM    geo_polygons p
                                     JOIN area_ids ua ON (ua.unique_area LIKE ('%' || UPPER(p.geo_area_key) || '%'))
                             WHERE   SUBSTR(p.geo_area_key, 1, 2) = stcode_i
                      ) s ON (      t.id = s.geo_polygon_id
                                AND t.unique_area_id = s.unique_area_id
                             )
                      WHEN NOT MATCHED THEN INSERT
                          (t.id, t.geo_area_key, t.unique_area_id, t.area_id, t.entered_by, t.status)
                      VALUES
                          (s.geo_polygon_id, s.geo_area_key, s.unique_area_id, s.area_id, s.entered_by, s.status);
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_areas_temp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build temp tables for UA/Polygon associations - gis_unique_areas_temp/gis_poly_areas_temp', paction=>1, puser=>user_i);


            -- Create association between Unique Area and Polygons --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create UA/Polygon associations - geo_unique_area_polygons', paction=>0, puser=>user_i);
            MERGE /*+index(t geo_unique_area_polygons_n2) index(s gis_poly_areas_temp_n1)*/ INTO geo_unique_area_polygons t
                USING ( SELECT  DISTINCT
                                id  geo_polygon_id,
                                unique_area_id,
                                entered_by,
                                status
                        FROM    gis_poly_areas_temp
                      ) s ON (      t.geo_polygon_id = s.geo_polygon_id
                                AND t.unique_area_id = s.unique_area_id
                             )
                      WHEN NOT MATCHED THEN INSERT
                          (t.geo_polygon_id, t.unique_area_id, t.entered_by, t.status)
                      VALUES
                          (s.geo_polygon_id, s.unique_area_id, s.entered_by, s.status);

            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_unique_area_polygons', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create UA/Polygon associations - geo_unique_area_polygons', paction=>1, puser=>user_i);


            -- Removed TAX_ID Attribute -- crapp-1003
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove TAX_ID UA attributes - geo_unique_area_attributes', paction=>0, puser=>user_i);
            FOR i IN taxids_removed LOOP
                UPDATE geo_unique_area_attributes
                    SET end_date = i.new_end_date
                WHERE value = i.taxid
                      AND geo_unique_area_id = i.ua_id
                      AND attribute_id = (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID');
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove TAX_ID UA attributes - geo_unique_area_attributes', paction=>1, puser=>user_i);


            -- Create TAX_ID Attribute -- crapp-1003
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create TAX_ID UA attributes - geo_unique_area_attributes', paction=>0, puser=>user_i);
            FOR i IN ua_taxids LOOP
                INSERT INTO geo_unique_area_attributes
                (
                    geo_unique_area_id
                    , attribute_id
                    , VALUE
                    , start_date
                    , entered_by
                    , status
                    , rid
                )
                VALUES
                    (
                        i.ua_id
                        , (SELECT id FROM additional_attributes WHERE name = 'Internal Tax Area ID')
                        , i.taxid
                        , TRUNC(l_date)
                        , user_i
                        , l_status
                        , i.rid
                    );
            END LOOP;
            COMMIT;
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_unique_area_attributes', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Create TAX_ID UA attributes - geo_unique_area_attributes', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'update_unique_areas', paction=>1, puser=>user_i);
        END update_unique_areas;



    -- ****************************************** --
    -- Map Jurisdictions to Unique Areas by State --
    -- ****************************************** --
    PROCEDURE map_juris_geo_areas (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER)
    IS
            l_sx     CLOB;
            l_rid    NUMBER;
            l_nkid   NUMBER;
            l_update_success NUMBER;
            l_exists NUMBER;

            CURSOR polygons IS
                SELECT  DISTINCT
                        jurisdiction_id
                        ,geo_polygon_id
                        ,start_date
                        ,end_date
                        ,rid
                        ,nkid
                FROM    gis_mapped_areas_temp
                ORDER BY jurisdiction_id;

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'map_juris_geo_areas', paction=>0, puser=>user_i);

            -- Determine if State already has mappings. If so, exit procedure -- crapp-2040
            SELECT COUNT(*)
            INTO   l_exists
            FROM   vjuris_geo_areas
            WHERE  state_code = stcode_i;

            IF l_exists = 0 THEN

                -- Determine list of Jurisdictions --
                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_areas_temp DROP STORAGE';
                INSERT INTO gis_areas_temp
                    (id, official_name, rid, nkid, geo_area, next_level, county, city, district, short_name, alt_name)
                    SELECT DISTINCT
                           j.id,
                           TRIM(REPLACE(REPLACE(j.official_name, CHR(10), ''), CHR(13), '')) official_name,
                           j.rid,
                           j.nkid,
                           tz.name geo_area,
                           CASE WHEN INSTR(j.official_name, ' CO)') > 0 THEN pl.name
                                ELSE nl.name
                           END next_level,
                           TRIM(REPLACE(REPLACE(za.zone_4_name, CHR(10), ''), CHR(13), '')) county,
                           TRIM(REPLACE(REPLACE(za.zone_5_name, CHR(10), ''), CHR(13), '')) city,
                           CASE WHEN INSTR(j.official_name, ' CO)') > 0 AND INSTR(j.official_name, '/') > 0
                                     AND tz.NAME = 'City' THEN TRIM( SUBSTR(j.official_name, INSTR(j.official_name, '/')+1, (INSTR(j.official_name, '(')-INSTR(j.official_name, '/')-2) ) )
                                WHEN INSTR(j.official_name, '/') > 0 AND tz.NAME = 'City'
                                     THEN TRIM( SUBSTR(j.official_name, INSTR(j.official_name, '/')+1, ( INSTR(j.official_name, ')')-INSTR(j.official_name, '/')-1 )))
                                ELSE NULL
                           END district,
                           TRIM(REPLACE(REPLACE(CASE WHEN tz.name = 'State' THEN SUBSTR(j.official_name, 1, 10)
                                                     WHEN INSTR(j.official_name, '(') > 0 THEN TRIM(SUBSTR(j.official_name, 1, INSTR(j.official_name, '(')-2))
                                                     ELSE TRIM(SUBSTR(j.official_name, 1, INSTR(j.official_name, ',')-1))
                                                END, CHR(10), ''), CHR(13), '')) short_name,
                           TRIM(REPLACE(REPLACE(CASE WHEN tz.name = 'State' AND INSTR(j.official_name, 'STATE (') = 0 THEN TRIM((SUBSTR(j.official_name, 1, 5) || ta.official_name))
                                                     WHEN tz.name = 'State' AND INSTR(j.official_name, 'STATE (') > 0
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')') - INSTR(j.official_name, '(')-1)))
                                                     WHEN tz.name = 'District'
                                                          AND INSTR(j.official_name, 'CITY)') > 0
                                                          AND NVL(za.zone_5_name, 'N/A') <> TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')') - INSTR(j.official_name, '(')-1)))
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')')-5 - INSTR(j.official_name, '(')-1)))
                                                     WHEN INSTR(j.official_name, '(') > 0 AND INSTR(j.official_name, ' CO)') = 0
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')') - INSTR(j.official_name, '(')-1)))
                                                     WHEN INSTR(j.official_name, ' CO)') > 0
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')')-3 - INSTR(j.official_name, '(')-1)))
                                                     ELSE NULL
                                                END, CHR(10), ''), CHR(13), '')) altname
                    FROM   jurisdictions j
                           JOIN sbxtax.tb_authorities ta ON (j.official_name = ta.name)
                           LEFT JOIN ( SELECT DISTINCT
                                              a.authority_name
                                              ,a.zone_4_name
                                              ,a.zone_5_name
                                       FROM   sbxtax.ct_zone_authorities a
                                              JOIN sbxtax.tb_zones z ON (a.zone_3_id = z.zone_id)
                                       WHERE  z.code_2char = stcode_i
                                              AND a.zone_7_name IS NULL
                                     ) za ON (j.official_name = za.authority_name)
                           JOIN sbxtax.tb_zone_levels tz ON (ta.effective_zone_level_id = tz.zone_level_id)
                           LEFT JOIN sbxtax.tb_zone_levels nl ON (ta.effective_zone_level_id-1 = nl.zone_level_id)
                           LEFT JOIN sbxtax.tb_zone_levels pl ON (ta.effective_zone_level_id+1 = pl.zone_level_id)
                    WHERE  j.next_rid IS NULL
                           AND ta.name LIKE (stcode_i || ' - %')
                    UNION -- Telco --
                    SELECT DISTINCT
                           j.id,
                           TRIM(REPLACE(REPLACE(j.official_name, CHR(10), ''), CHR(13), '')) official_name,
                           j.rid,
                           j.nkid,
                           tz.name geo_area,
                           CASE WHEN INSTR(j.official_name, ' CO)') > 0 THEN pl.name
                                ELSE nl.name
                           END next_level,
                           TRIM(REPLACE(REPLACE(za.zone_4_name, CHR(10), ''), CHR(13), '')) county,
                           TRIM(REPLACE(REPLACE(za.zone_5_name, CHR(10), ''), CHR(13), '')) city,
                           CASE WHEN INSTR(j.official_name, ' CO)') > 0 AND INSTR(j.official_name, '/') > 0
                                     AND tz.NAME = 'City' THEN TRIM( SUBSTR(j.official_name, INSTR(j.official_name, '/')+1, (INSTR(j.official_name, '(')-INSTR(j.official_name, '/')-2) ) )
                                WHEN INSTR(j.official_name, '/') > 0 AND tz.NAME = 'City'
                                     THEN TRIM( SUBSTR(j.official_name, INSTR(j.official_name, '/')+1, ( INSTR(j.official_name, ')')-INSTR(j.official_name, '/')-1 )))
                                ELSE NULL
                           END district,
                           TRIM(REPLACE(REPLACE(CASE WHEN tz.name = 'State' THEN SUBSTR(j.official_name, 1, 10)
                                                     WHEN INSTR(j.official_name, '(') > 0 THEN TRIM(SUBSTR(j.official_name, 1, INSTR(j.official_name, '(')-2))
                                                     ELSE TRIM(SUBSTR(j.official_name, 1, INSTR(j.official_name, ',')-1))
                                                END, CHR(10), ''), CHR(13), '')) short_name,
                           TRIM(REPLACE(REPLACE(CASE WHEN tz.name = 'State' AND INSTR(j.official_name, 'STATE (') = 0 THEN TRIM((SUBSTR(j.official_name, 1, 5) || ta.official_name))
                                                     WHEN tz.name = 'State' AND INSTR(j.official_name, 'STATE (') > 0
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')') - INSTR(j.official_name, '(')-1)))
                                                     WHEN tz.name = 'District'
                                                          AND INSTR(j.official_name, 'CITY)') > 0
                                                          AND NVL(za.zone_5_name, 'N/A') <> TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')') - INSTR(j.official_name, '(')-1)))
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')')-5 - INSTR(j.official_name, '(')-1)))
                                                     WHEN INSTR(j.official_name, '(') > 0 AND INSTR(j.official_name, ' CO)') = 0
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')') - INSTR(j.official_name, '(')-1)))
                                                     WHEN INSTR(j.official_name, ' CO)') > 0
                                                          THEN stcode_i || ' - ' || TRIM(SUBSTR(j.official_name, INSTR(j.official_name, '(')+1, (INSTR(j.official_name, ')')-3 - INSTR(j.official_name, '(')-1)))
                                                     ELSE NULL
                                                END, CHR(10), ''), CHR(13), '')) altname
                    FROM   jurisdictions j
                           JOIN sbxtax4.tb_authorities ta ON (j.official_name = ta.name)
                           LEFT JOIN ( SELECT DISTINCT
                                              a.authority_name
                                              ,a.zone_4_name
                                              ,a.zone_5_name
                                       FROM   sbxtax4.ct_zone_authorities a
                                              JOIN sbxtax4.tb_zones z ON (a.zone_3_id = z.zone_id)
                                       WHERE  z.code_2char = stcode_i
                                              AND a.zone_7_name IS NULL
                                     ) za ON (j.official_name = za.authority_name)
                           JOIN sbxtax4.tb_zone_levels tz ON (ta.effective_zone_level_id = tz.zone_level_id)
                           LEFT JOIN sbxtax4.tb_zone_levels nl ON (ta.effective_zone_level_id-1 = nl.zone_level_id)
                           LEFT JOIN sbxtax4.tb_zone_levels pl ON (ta.effective_zone_level_id+1 = pl.zone_level_id)
                    WHERE  j.next_rid IS NULL
                           AND ta.name LIKE (stcode_i || ' - %');
                COMMIT;
                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_areas_temp', cascade => TRUE);

                -- Set County/City for NULL values --
                UPDATE gis_areas_temp
                    SET county = TRIM(SUBSTR(short_name, 6))
                WHERE  geo_area = 'County'
                    AND next_level = 'City'
                    AND city IS NULL
                    AND district IS NULL;
                COMMIT;

                UPDATE gis_areas_temp
                    SET county = TRIM(SUBSTR(alt_name, 6)),
                        city   = TRIM(SUBSTR(short_name, 6))
                WHERE  geo_area = 'City'
                    AND next_level = 'County'
                    AND city IS NULL
                    AND district IS NULL;
                COMMIT;

                UPDATE gis_areas_temp
                    SET county = TRIM(SUBSTR(alt_name, 6)),
                        city   = SUBSTR(short_name, 6, INSTR(short_name, '/')-6),
                        short_name = SUBSTR(short_name, 1, INSTR(short_name, '/')-1)
                WHERE  geo_area = 'City'
                    AND next_level = 'County'
                    AND city IS NULL
                    AND district IS NOT NULL;
                COMMIT;


                -- ************************ --
                -- Build Temp Mapping table --
                -- ************************ --
                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_mapped_areas_temp DROP STORAGE';
                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_poly_areas_temp DROP STORAGE';

                INSERT INTO gis_poly_areas_temp
                    (id, geo_area_key, geo_area, state_code, state_name, start_date, end_date, official_name, county_name, city_name, rid, nkid)
                    SELECT  DISTINCT
                            p.id
                            , p.geo_area_key
                            , ac.NAME geo_area
                            , l.state_code
                            , l.state_name
                            , TO_CHAR(SYSDATE, 'dd-Mon-yyyy') start_date
                            , TO_CHAR('', 'dd-Mon-yyyy') end_date
                            , UPPER(SUBSTR(p.geo_area_key, 1, 2) ||' - '|| REPLACE(SUBSTR(p.geo_area_key, INSTR(p.geo_area_key, '-', 4, 1) + 1), '-',' ')) official_name
                            , CASE WHEN ac.NAME <> 'State' THEN UPPER(l.county_name)
                                   ELSE NULL
                              END county_name
                            , CASE WHEN ac.NAME <> 'State' THEN UPPER(l.city_name)
                                   ELSE NULL
                              END city_name
                            , p.rid
                            , p.nkid
                    FROM    geo_usps_lookup l
                            JOIN geo_polygons p ON (l.geo_polygon_id = p.id)
                            JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
                            JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
                    WHERE   l.state_code = stcode_i
                            AND p.next_rid IS NULL;
                COMMIT;
                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_poly_areas_temp', cascade => TRUE);

                -- 1
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                    SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN gis_areas_temp a ON ( s.official_name   = a.alt_name
                                                       AND s.geo_area   <> a.geo_area
                                                       AND s.county_name = a.county
                                                       AND s.city_name   = a.city
                                                     )
                    WHERE   a.alt_name IS NOT NULL
                        AND a.geo_area = 'County'
                        AND s.county_name <> s.city_name;
                COMMIT;

                -- 2
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                    SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN gis_areas_temp a ON ( s.official_name   = a.short_name --a.alt_name
                                                       AND s.geo_area   = a.geo_area
                                                       AND s.county_name = a.county
                                                       AND s.city_name   = a.city
                                                     )
                    WHERE   a.alt_name IS NOT NULL
                        AND a.geo_area = 'City'
                        AND s.county_name <> s.city_name
                        AND NOT EXISTS ( SELECT 1
                                         FROM   gis_mapped_areas_temp m
                                         WHERE  m.jurisdiction_id = a.id
                                                AND m.geo_polygon_id = s.id
                                                AND m.rid = s.rid
                                       );
                COMMIT;

                -- 3
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                    SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN gis_areas_temp a ON ( s.official_name   = a.alt_name
                                                       AND s.geo_area    = a.next_level
                                                       AND s.county_name = a.county
                                                       AND s.city_name   = a.city
                                                     )
                    WHERE   a.alt_name IS NOT NULL
                        AND s.county_name = s.city_name
                        AND NOT EXISTS ( SELECT 1
                                         FROM   gis_mapped_areas_temp m
                                         WHERE  m.jurisdiction_id = a.id
                                                AND m.geo_polygon_id = s.id
                                                AND m.rid = s.rid
                                       );
                COMMIT;

                -- 4
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                    SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN gis_areas_temp a ON ( s.official_name = a.short_name
                                                       AND s.geo_area  = a.geo_area
                                                       AND s.county_name = a.county
                                                       AND NVL(s.city_name, 'N/A') = NVL(a.city, 'N/A')
                                                     )
                    WHERE   a.alt_name IS NULL
                        AND a.geo_area <> 'District'
                        AND NOT EXISTS ( SELECT 1
                                         FROM   gis_mapped_areas_temp m
                                         WHERE  m.jurisdiction_id = a.id
                                                AND m.geo_polygon_id = s.id
                                                AND m.rid = s.rid
                                       );
                COMMIT;

                -- 5    (05/15/15 - replaces original 5,6,7,8 per crapp-1697)
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                    SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN ( SELECT DISTINCT
                                          location_code
                                          , t.official_name
                                          , t.id
                                   FROM   gis_areas_temp t
                                          JOIN gis_stj_lookup l ON t.official_name = l.authority_name
                                 ) a ON ( SUBSTR(s.geo_area_key, 4, INSTR(s.geo_area_key, '-', 4, 1) - 4) = a.location_code )
                    WHERE  NOT EXISTS ( SELECT 1
                                        FROM   gis_mapped_areas_temp m
                                        WHERE  m.jurisdiction_id = a.id
                                               AND m.geo_polygon_id = s.id
                                               AND m.rid = s.rid
                                      );
                COMMIT;

                -- 6    -- Added State Level back - 01/17/15
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                    SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN gis_areas_temp a ON ( s.official_name = a.alt_name
                                                       AND s.geo_area = a.geo_area
                                                     )
                    WHERE   a.geo_area = 'State'
                            AND NOT EXISTS ( SELECT 1
                                             FROM   gis_mapped_areas_temp m
                                             WHERE  m.jurisdiction_id = a.id
                                                    AND m.geo_polygon_id = s.id
                                                    AND m.rid = s.rid
                                           );
                COMMIT;

                -- 7   -- Added to pickup the County only Mappings - 02/19/15
                INSERT INTO gis_mapped_areas_temp
                    (jurisdiction_id, geo_polygon_id, start_date, end_date, rid, nkid)
                   SELECT  DISTINCT
                            a.id jurisdiction_id
                            ,s.id geo_polygon_id
                            ,s.start_date
                            ,s.end_date
                            ,s.rid
                            ,s.nkid
                            --,a.official_name, s.county_name, s.city_name
                    FROM    gis_poly_areas_temp s
                            JOIN gis_areas_temp a ON ( s.official_name   = a.short_name
                                                       AND s.geo_area    = a.geo_area
                                                       AND s.county_name = a.county
                                                     )
                    WHERE   a.alt_name IS NULL
                        AND a.geo_area = 'County'
                        AND a.city IS NULL
                        AND NOT EXISTS ( SELECT 1
                                         FROM   gis_mapped_areas_temp m
                                         WHERE  m.jurisdiction_id = a.id
                                                AND m.geo_polygon_id = s.id
                                                AND m.rid = s.rid
                                       );
                COMMIT;
                DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_mapped_areas_temp', cascade => TRUE);


                -- ************************************* --
                -- Loop through Areas and create mapping --
                -- ************************************* --
                FOR g IN polygons LOOP <<area_loop>>
                    SELECT XMLRoot(
                                    XMLElement( "juris_geo_areas",
                                                XMLForest( d.id "id",
                                                           d.jurisdiction_id "jurisdiction_id",
                                                           d.geo_polygon_id  "geo_polygon_id",
                                                           d.requires_establishment "requires_establishment",
                                                           d.start_date "start_date",
                                                           d.end_date   "end_date",
                                                           d.entered_by "entered_by",
                                                           d.rid  "rid",
                                                           d.nkid "nkid",
                                                           d.modified "modified",
                                                           d.deleted  "deleted"
                                                         ),
                                                XMLElement( "tag",
                                                            XMLForest( (SELECT id FROM tags WHERE NAME = 'United States') "tag_id",
                                                                       0 "deleted",
                                                                       0 "status"
                                                                     )
                                                          ),
                                                XMLElement( "tag",
                                                            XMLForest( (SELECT id FROM tags WHERE NAME = 'Determination') "tag_id",
                                                                       0 "deleted",
                                                                       0 "status"
                                                                     )
                                                          )
                                              ), version '1.0'
                                  ).getClobVal() area
                    INTO l_sx
                    FROM ( SELECT  '' id,
                                   g.jurisdiction_id,
                                   g.geo_polygon_id,
                                   0 requires_establishment,
                                   g.start_date,
                                   g.end_date,
                                   user_i entered_by,
                                   g.rid,
                                   g.nkid,
                                   1 modified,
                                   0 deleted
                           FROM    dual
                         ) d;

                    gis.XMLProcess_Form_JurisArea(sx=> l_sx, update_success=> l_update_success, rid_o=> l_rid, nkid_o=> l_nkid);
                    COMMIT;

                END LOOP area_loop;
            END IF; -- l_exists
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'map_juris_geo_areas', paction=>1, puser=>user_i);

        END map_juris_geo_areas;


    -- ******************************************************* --
    -- Archive state specific UA_ZIP9 table used durung import --
    --                                                         --
    -- Replaces scheduled Python script running on local GIS   --
    -- computer every 5 minutes                                --
    -- ******************************************************* --
    PROCEDURE archive_uaz9(stcode_i VARCHAR2, user_i NUMBER, pID_i NUMBER) IS -- crapp-3451
            l_host   VARCHAR2(10 CHAR);
        BEGIN
            -- Determine the Server Host --
            SELECT NVL(h.displayname, 'N/A') dsphost
            INTO   l_host
            FROM dual d
                 LEFT JOIN geo_etl_server_hosts h ON (h.serverhost = SYS_CONTEXT('USERENV', 'SERVER_HOST'));

            IF l_host = 'PROD' THEN -- We only want to archive the UA_ZIP9 table when processing an Import in PROD --
                gis_etl_p(pID_i, stcode_i, 'archive_uaz9', 0, user_i);

                -- Archive the current UA_Zip9 table via GIS package --
                gis.gis_export.archive_uazip9@gis.corp.ositax.com(stcode_i, user_i, pID_i);

                gis_etl_p(pID_i, stcode_i, 'archive_uaz9', 1, user_i);
            END IF;
        END archive_uaz9;

END load_gis;
/