CREATE OR REPLACE PACKAGE BODY sbxtax4.gis_etl
IS

    g_tdp varchar2(100) := 'Sabrix US Tax Data';

    -- ***************** --
    --     CR_EXTRACT    --
    -- ***************** --


    PROCEDURE zone_data IS  -- 07/27/17 - crapp-3523
        l_id    NUMBER;
        l_state VARCHAR2(50 CHAR);  -- crapp-3523
    BEGIN
        etl_proc_log_p('GIS_ETL.ZONE_DATA','Procedure - start','GIS',NULL,NULL);
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get Zone adds - start','GIS',NULL,NULL);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_us_zone_changes DROP STORAGE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_zone_attributes DROP STORAGE';

        SELECT DISTINCT zone_3_name
        INTO l_state
        FROM content_repo.gis_ztree_tmp;

        --get adds: Zones that exist in Content Repo but not in Determination
        insert into tdr_etl_us_zone_changes(id,  state, county, city, postcode, plus4, source_db, change_type)(
        select rownum, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name , 'CONTENT_REPO', 'Add'
        from (
            select distinct zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                   , code_2char, code_3char, code_fips, default_flag, reverse_flag, terminator_flag
            from content_repo.gis_ztree_tmp -- crapp-3363
            minus
            select zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                   , code_2char, code_3char, code_fips, default_flag, reverse_flag, terminator_flag
            from   ct_zone_tree
            WHERE  zone_3_name = l_state    -- crapp-3523
            )
         );
        COMMIT;

        SELECT max(id)
        INTO l_id
        FROM tdr_etl_us_zone_changes;
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get Zone adds - end','GIS',NULL,NULL);


        -- get deletes --
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get Zone deletes - start','GIS',NULL,NULL);

        INSERT INTO tdr_etl_us_zone_changes(id,  state, county, city, postcode, plus4, source_db, change_type)(
        SELECT l_id+rownum, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name ,'DETERMINATION','Delete'
        FROM (
              SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
              FROM   ct_zone_tree zt
              WHERE  zt.zone_3_name = l_state   -- crapp-3523, changed from "IS NOT NULL" to use state name
              AND EXISTS (
                          SELECT 1
                          FROM  content_repo.gis_ztree_tmp gz -- crapp-3363
                          WHERE gz.zone_3_name = zt.zone_3_name
                         )
              MINUS
              SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
              FROM   content_repo.gis_ztree_tmp  -- crapp-3363
             )
         );
        COMMIT;

        SELECT MAX(id)
        INTO l_id
        FROM tdr_etl_us_zone_changes;
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get Zone deletes - end','GIS',NULL,NULL);


        -- get updates --
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get Zone updates - start','GIS',NULL,NULL);

        INSERT INTO tdr_etl_us_zone_changes(id,  state, county, city, postcode, plus4, source_db, change_type)
        (
            SELECT l_id+rownum, det.zone_3_name, det.zone_4_name, det.zone_5_name, det.zone_6_name, det.zone_7_name,'DETERMINATION','Update'
            FROM   ct_zone_tree det
                   JOIN content_repo.gis_ztree_tmp crt on (
                                                           det.zone_3_name = crt.zone_3_name
                                                           AND det.zone_4_name = crt.zone_4_name
                                                           AND NVL(det.zone_5_name,'NULL CITY')  = NVL(crt.zone_5_name,'NULL CITY')
                                                           AND NVL(det.zone_6_name,'NULL ZIP')   = NVL(crt.zone_6_name,'NULL ZIP')
                                                           AND NVL(det.zone_7_name,'NULL PLUS4') = NVL(crt.zone_7_name,'NULL PLUS4')
                                                          )
            WHERE det.zone_3_name = l_state -- crapp-3523
                  AND
                  (    NVL(det.code_2char,'xxx')    != NVL(crt.code_2char,'xxx')
                    OR NVL(det.code_3char,'xxxx')   != NVL(crt.code_3char,'xxxx')
                    OR NVL(det.code_fips,'xxx')     != NVL(crt.code_fips,'xxx')
                    OR NVL(det.default_flag,'N')    != NVL(crt.default_flag,'N')
                    OR NVL(det.reverse_flag,'N')    != NVL(crt.reverse_flag,'N')
                    OR NVL(det.terminator_flag,'N') != NVL(crt.terminator_flag,'N')
                  )
        );
        COMMIT;
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get Zone updates - end','GIS',NULL,NULL);


        -- get attributes from Content Repo --
        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get attributes - start','GIS',NULL,NULL);

        INSERT INTO tdr_etl_zone_attributes (tmp_id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag)
        (
            SELECT DISTINCT id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag
            FROM   content_repo.gis_ztree_tmp tz    -- crapp-3363
                   JOIN tdr_etl_us_zone_changes usz ON (
                                                        usz.state  = tz.zone_3_name
                                                    AND usz.county = tz.zone_4_name
                                                    AND NVL(usz.city,'NULL CITY')    = NVL(tz.zone_5_name,'NULL CITY')
                                                    AND NVL(usz.postcode,'NULL ZIP') = NVL(tz.zone_6_name,'NULL ZIP')
                                                    AND NVL(usz.plus4,'NULL PLUS4')  = NVL(tz.zone_7_name,'NULL PLUS4')
                                                   )
            WHERE usz.source_db = 'CONTENT_REPO'
        );
        COMMIT;

        -- get attributes from Determination --
        INSERT INTO tdr_etl_zone_attributes (tmp_id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag)
        (
            SELECT DISTINCT id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag
            FROM   content_repo.gis_ztree_tmp tz    -- crapp-3363
                   JOIN tdr_etl_us_zone_changes usz ON (
                                                        usz.state  = tz.zone_3_name
                                                    AND usz.county = tz.zone_4_name
                                                    AND NVL(usz.city,'NULL CITY')    = NVL(tz.zone_5_name,'NULL CITY')
                                                    AND NVL(usz.postcode,'NULL ZIP') = NVL(tz.zone_6_name,'NULL ZIP')
                                                    AND NVL(usz.plus4,'NULL PLUS4')  = NVL(tz.zone_7_name,'NULL PLUS4')
                                                   )
            WHERE usz.change_type = 'Update'
        );
        COMMIT;

        etl_proc_log_p('GIS_ETL.ZONE_DATA',' - Get attributes - end','GIS',NULL,NULL);
        etl_proc_log_p('GIS_ETL.ZONE_DATA','Procedure - end','GIS',NULL,NULL);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Zone area data error - '||SQLERRM);
    END zone_data;


    PROCEDURE zone_authority_data(make_changes_i IN NUMBER) IS  -- 07/27/17 - crapp-3523
        l_id    NUMBER;
        l_state VARCHAR2(50 CHAR);  -- crapp-3523
    BEGIN
        etl_proc_log_p('GIS_ETL.ZONE_AUTHORITY_DATA','Procedure - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_us_zone_authorities DROP STORAGE';

        SELECT DISTINCT zone_3_name
        INTO l_state
        FROM content_repo.gis_ztree_tmp;

        -- get adds: Zone Authorities that exist in Content Repo but not in Determination --
        etl_proc_log_p('GIS_ETL.ZONE_AUTHORITY_DATA',' - Get adds - start','GIS',NULL,NULL);

        IF (make_changes_i = 1) THEN
            -- Exclude any Invalid Authorities - crapp-2244 --
            INSERT INTO tdr_etl_us_zone_authorities(id, state, county, city, postcode, plus4, authority, source_db, change_type)
            (
            SELECT ROWNUM, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name , authority_name, 'CONTENT_REPO', 'Add'
            FROM (
                 SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   content_repo.gis_authorities_tmp    -- crapp-3363
                 MINUS
                 SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   ct_zone_authorities
                 WHERE  zone_3_name = l_state   -- crapp-3523
                 ) a
            WHERE authority_name NOT IN (SELECT DISTINCT gis_name FROM content_repo.gis_zone_juris_auths_tmp)   -- crapp-3363
            );
        ELSE
            INSERT INTO tdr_etl_us_zone_authorities(id, state, county, city, postcode, plus4, authority, source_db, change_type)
            (
            SELECT ROWNUM, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name, 'CONTENT_REPO', 'Add'
            FROM (
                 SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   content_repo.gis_authorities_tmp    -- crapp-3363
                 MINUS
                 SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   ct_zone_authorities
                 WHERE  zone_3_name = l_state   -- crapp-3523
                 )
            );
        END IF;
        COMMIT;

        SELECT MAX(id)
        INTO l_id
        FROM tdr_etl_us_zone_authorities;
        etl_proc_log_p('GIS_ETL.ZONE_AUTHORITY_DATA',' - Get adds - end','GIS',NULL,NULL);


        -- get deletes --
        etl_proc_log_p('GIS_ETL.ZONE_AUTHORITY_DATA',' - Get deletes - start','GIS',NULL,NULL);

        INSERT INTO tdr_etl_us_zone_authorities(id, state, county, city, postcode, plus4, authority, source_db, change_type)
        (
        SELECT l_id+ROWNUM, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name, 'DETERMINATION', 'Delete'
        FROM (
             SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,authority_name
             FROM   ct_zone_authorities zt
             WHERE  zt.zone_3_name = l_state   -- crapp-3523, changed from "IS NOT NULL" to use state name
             AND EXISTS (
                        SELECT 1
                        FROM   content_repo.gis_authorities_tmp gz  -- crapp-3363
                        WHERE  gz.zone_3_name = zt.zone_3_name
                        )
             MINUS
             SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,authority_name
             FROM   content_repo.gis_authorities_tmp    -- crapp-3363
             )
        );
        COMMIT;
        etl_proc_log_p('GIS_ETL.ZONE_AUTHORITY_DATA',' - Get deletes - end','GIS',NULL,NULL);
        etl_proc_log_p('GIS_ETL.ZONE_AUTHORITY_DATA','Procedure - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Zone data error - '||SQLERRM);
    END zone_authority_data;



    -- ***************** --
    --   DET_TRANSFORM   --
    -- ***************** --



    PROCEDURE build_tb_zones IS   -- 07/27/17 - crapp-3523
        l_merch_id NUMBER;
        l_zone1_id NUMBER;
        l_state    VARCHAR2(50 CHAR);  -- crapp-3523
        vcurrent_schema VARCHAR2(50);

        TYPE r_zoneupd IS RECORD   -- crapp-3523
        (
            state            tdr_etl_us_zone_changes.state%TYPE
          , county           tdr_etl_us_zone_changes.county%TYPE
          , city             tdr_etl_us_zone_changes.city%TYPE
          , postcode         tdr_etl_us_zone_changes.postcode%TYPE
          , plus4            tdr_etl_us_zone_changes.plus4%TYPE
          , code_2char       tdr_etl_zone_attributes.code_2char%TYPE
          , code_3char       tdr_etl_zone_attributes.code_3char%TYPE
          , code_fips        tdr_etl_zone_attributes.code_fips%TYPE
          , reverse_flag     tdr_etl_zone_attributes.reverse_flag%TYPE
          , terminator_flag  tdr_etl_zone_attributes.terminator_flag%TYPE
          , default_flag     tdr_etl_zone_attributes.default_flag%TYPE
        );
        TYPE t_zoneupd IS TABLE OF r_zoneupd;
        v_zoneupd t_zoneupd;

        CURSOR zone_deletes IS
            SELECT *
            FROM tdr_etl_us_zone_changes
            WHERE change_type = 'Delete'
            ORDER BY CASE WHEN county IS NULL THEN 1 WHEN city IS NULL THEN 2 WHEN postcode IS NULL THEN 3 ELSE 4 END;

        CURSOR zone_updates IS
            SELECT DISTINCT state, county, city, postcode, plus4, code_2char, code_3char, code_fips, reverse_flag, terminator_flag, default_flag
            FROM tdr_etl_us_zone_changes zc
                 JOIN tdr_etl_zone_attributes za ON (za.tmp_id = zc.id)
            WHERE change_type = 'Update';

        CURSOR zone_adds IS
            SELECT zc.*, za.*, CASE WHEN zc.plus4 IS NOT NULL THEN SUBSTR(zc.plus4,1,4) END range_min,
                   CASE WHEN zc.plus4 IS NOT NULL THEN SUBSTR(zc.plus4,6,4) END range_max
            FROM tdr_etl_us_zone_changes zc
                 JOIN tdr_etl_zone_attributes za ON (za.tmp_id = zc.id)
            WHERE change_type = 'Add';
    BEGIN
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES','Procedure - start','GIS',NULL,NULL);

        -- CRAPP-3174, Dynamic extraction of schema name to reference tables where needed
        SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) INTO vcurrent_schema FROM dual;

        SELECT DISTINCT zone_3_name
        INTO l_state
        FROM content_repo.gis_ztree_tmp;

        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Get existing CT Zone Tree - start','GIS',NULL,NULL);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_ct_zone_tree DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX tdr_etl_ct_zone_tree_n1 UNUSABLE';  -- crapp-3523

        --pull in the existing zone tree for each zone in tdr_etl_us_zone_changes
        INSERT INTO tdr_etl_ct_zone_tree (merchant_id, primary_key, zone_1_id, zone_1_name, zone_1_level_id, zone_2_id,
                    zone_2_name, zone_2_level_id, zone_3_id, zone_3_name, zone_3_level_id, zone_4_id, zone_4_name,
                    zone_4_level_id, zone_5_id, zone_5_name, zone_5_level_id, zone_6_id, zone_6_name, zone_6_level_id, zone_7_id,
                    zone_7_name, zone_7_level_id, tax_parent_zone, eu_zone_as_of_date, code_2char, code_3char, code_iso, code_fips,
                    reverse_flag, terminator_flag, default_flag, range_min, range_max, creation_date, zone_8_name, zone_8_id,
                    zone_8_level_id, zone_9_name, zone_9_id, zone_9_level_id)
        (
         SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_1_level_id, zone_2_id,
                zone_2_name, zone_2_level_id, zone_3_id, zone_3_name, zone_3_level_id, zone_4_id, zone_4_name,
                zone_4_level_id, zone_5_id, zone_5_name, zone_5_level_id, zone_6_id, zone_6_name, zone_6_level_id, zone_7_id,
                zone_7_name, zone_7_level_id, tax_parent_zone, eu_zone_as_of_date, code_2char, code_3char, code_iso, code_fips,
                reverse_flag, terminator_flag, default_flag, range_min, range_max, creation_date, zone_8_name, zone_8_id,
                zone_8_level_id, zone_9_name, zone_9_id, zone_9_level_id
         FROM  ct_zone_tree zt
         WHERE zt.zone_3_name = l_state   -- crapp-3523, changed from "IS NOT NULL" to use state name
               /*   -- crapp-3523, removed - now using state name
               AND EXISTS (
                           SELECT 1
                           FROM tdr_etl_us_zone_changes zc
                           WHERE zc.state = zt.zone_3_name
                           AND zc.state IS NOT NULL
                          )
               */
        );
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX tdr_etl_ct_zone_tree_n1 REBUILD';  -- crapp-3523
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'tdr_etl_ct_zone_tree', cascade => TRUE);
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Get existing CT Zone Tree - end','GIS',NULL,NULL);

        SELECT MAX(merchant_id), MAX(zone_1_id)
        INTO l_merch_id, l_zone1_id
        FROM tdr_etl_ct_zone_tree;


        --delete first
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process deletes - start','GIS',NULL,NULL);
        for d in zone_deletes loop
            IF d.county IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_4_name IS NULL
                AND zone_3_name = d.state;
            ELSIF d.city IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_5_name IS NULL
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            ELSIF d.postcode IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_6_name IS NULL
                AND zone_5_name = d.city
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            ELSIF d.plus4 IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_7_name IS NULL
                AND zone_6_name = d.postcode
                AND zone_5_name = d.city
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            ELSE
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_7_name = d.plus4
                AND zone_6_name = d.postcode
                AND zone_5_name = d.city
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            END IF;
            COMMIT;
        end loop;
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process deletes - end','GIS',NULL,NULL);


        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process updates - start','GIS',NULL,NULL);
        -- crapp-3523 -- changed to limited fetch loop
        OPEN zone_updates;
        LOOP
            FETCH zone_updates BULK COLLECT INTO v_zoneupd LIMIT 2000;

            FORALL u IN 1..v_zoneupd.COUNT
                UPDATE tdr_etl_ct_zone_tree
                    SET code_2char      = v_zoneupd(u).code_2char,
                        code_3char      = v_zoneupd(u).code_3char,
                        code_fips       = v_zoneupd(u).code_fips,
                        reverse_flag    = v_zoneupd(u).reverse_flag,
                        terminator_flag = v_zoneupd(u).terminator_flag,
                        default_flag    = v_zoneupd(u).default_flag
                WHERE zone_3_name = v_zoneupd(u).state
                      AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(v_zoneupd(u).county,'ZONE_4_NAME')
                      AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(v_zoneupd(u).city,'ZONE_5_NAME')
                      AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(v_zoneupd(u).postcode,'ZONE_6_NAME')
                      AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(v_zoneupd(u).plus4,'ZONE_7_NAME');
            COMMIT;

            EXIT WHEN zone_updates%NOTFOUND;
        END LOOP;
        COMMIT;
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process updates - end','GIS',NULL,NULL);


        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process adds - start','GIS',NULL,NULL);
        for a in zone_adds loop
            INSERT INTO tdr_etl_ct_zone_tree (MERCHANT_ID,ZONE_1_ID,ZONE_1_NAME,ZONE_2_NAME,ZONE_3_NAME,ZONE_4_NAME,
                ZONE_5_NAME,ZONE_6_NAME,ZONE_7_NAME,TAX_PARENT_ZONE,CODE_2CHAR,CODE_3CHAR,CODE_FIPS,
                REVERSE_FLAG,TERMINATOR_FLAG,DEFAULT_FLAG,RANGE_MIN,RANGE_MAX)
            VALUES
                (l_merch_id,l_zone1_id,'WORLD','UNITED STATES',a.state,a.county,a.city,a.postcode,a.plus4,a.state,
                a.code_2char, a.code_3char, a.code_fips, a.reverse_flag, a.terminator_flag, a.default_flag,
                a.range_min, a.range_max);
            COMMIT;
        end loop;
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process adds - end','GIS',NULL,NULL);

        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES','Procedure - end','GIS',NULL,NULL);
    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process failed with '||SQLERRM,'GIS',NULL,NULL);
            RAISE_APPLICATION_ERROR(-20001,'Build_TB_Zones timeout.');
        WHEN OTHERS THEN
            etl_proc_log_p('GIS_ETL.BUILD_TB_ZONES',' - Process failed with '||SQLERRM,'GIS',NULL,NULL);
            RAISE_APPLICATION_ERROR(-20002,'Build_TB_Zones error - '||SQLERRM);
    END build_tb_zones;



    PROCEDURE build_tb_zone_authorities(make_changes_i IN NUMBER) IS  -- 07/28/17 - crapp-3523
        l_id  NUMBER;
        l_rec NUMBER := 0;
        vcurrent_schema VARCHAR2(50);
        l_state         VARCHAR2(50 CHAR);  -- crapp-3523

        TYPE r_zoneauth IS RECORD   -- crapp-3523
        (
            id          tdr_etl_us_zone_authorities.id%TYPE
          , state       tdr_etl_us_zone_authorities.state%TYPE
          , county      tdr_etl_us_zone_authorities.county%TYPE
          , city        tdr_etl_us_zone_authorities.city%TYPE
          , postcode    tdr_etl_us_zone_authorities.postcode%TYPE
          , plus4       tdr_etl_us_zone_authorities.plus4%TYPE
          , authority   tdr_etl_us_zone_authorities.authority%TYPE
          , source_db   tdr_etl_us_zone_authorities.source_db%TYPE
          , change_type tdr_etl_us_zone_authorities.change_type%TYPE
        );
        TYPE t_zoneauth IS TABLE OF r_zoneauth;
        v_zoneauth t_zoneauth;

        CURSOR detaches IS
            SELECT *
            FROM   tdr_etl_us_zone_authorities
            WHERE  change_type = 'Delete';

        CURSOR attaches IS
            SELECT zc.*
            FROM   tdr_etl_us_zone_authorities zc
            WHERE  change_type = 'Add';

    BEGIN
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES','Procedure - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

        -- CRAPP-3174, Dynamic extraction of schema name to reference tables where needed
        SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) INTO vcurrent_schema FROM dual;

        SELECT DISTINCT zone_3_name
        INTO l_state
        FROM content_repo.gis_ztree_tmp;

        -- pull in the existing zone authorities for each zone in tdr_etl_ct_zone_authorities --
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES',' - Get existing CT Zone Authorities - start','GIS',NULL,NULL);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_ct_zone_authorities DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX tdr_etl_ct_zone_auths_n1 UNUSABLE';  -- 07/07/16

        INSERT INTO tdr_etl_ct_zone_authorities
            (merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_id, zone_2_name, zone_3_id, zone_3_name, zone_4_id, zone_4_name,
             zone_5_id, zone_5_name, zone_6_id, zone_6_name, zone_7_name, authority_name)   -- , creation_date - removed column 07/07/16
            (
            SELECT DISTINCT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_id, zone_2_name, zone_3_id, zone_3_name, zone_4_id, zone_4_name,
                   zone_5_id, zone_5_name, zone_6_id, zone_6_name, zone_7_name, authority_name   -- , creation_date - removed column 07/07/16
            FROM   ct_zone_authorities zt
            WHERE  zt.zone_3_name = l_state   -- crapp-3523, changed from "IS NOT NULL" to use state name
                   /* -- crapp-3523, removed - now using state name
                   AND EXISTS (
                                SELECT 1
                                FROM   tdr_etl_us_zone_authorities zc
                                WHERE  zc.state = zt.zone_3_name
                                       AND zc.state IS NOT NULL
                              )
                   */
            );
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX tdr_etl_ct_zone_auths_n1 REBUILD';  -- 07/07/16
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'tdr_etl_ct_zone_authorities', cascade => TRUE);  -- CRAPP-3174
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES',' - Get existing CT Zone Authorities - end','GIS',NULL,NULL);


        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES',' - Process detaches - start','GIS',NULL,NULL);
        -- crapp-3523 -- changed to limited fetch loop
        OPEN detaches;
        LOOP
            FETCH detaches BULK COLLECT INTO v_zoneauth LIMIT 25000;
            l_rec := v_zoneauth.COUNT;

            FORALL d IN 1..v_zoneauth.COUNT
                DELETE FROM tdr_etl_ct_zone_authorities
                WHERE  zone_3_name = v_zoneauth(d).state
                       AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(v_zoneauth(d).county,'ZONE_4_NAME')
                       AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(v_zoneauth(d).city,'ZONE_5_NAME')
                       AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(v_zoneauth(d).postcode,'ZONE_6_NAME')
                       AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(v_zoneauth(d).plus4,'ZONE_7_NAME')
                       AND authority_name = v_zoneauth(d).authority;
            COMMIT;
            etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES','   - Authority detaches - commited '||l_rec||' records','GIS',NULL,NULL);

            EXIT WHEN detaches%NOTFOUND;
        END LOOP;
        COMMIT;
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES',' - Process detaches - end','GIS',NULL,NULL);


        SELECT MAX(primary_key)
        INTO l_id
        FROM ct_zone_authorities;


        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES',' - Process attaches - start','GIS',NULL,NULL);
        EXECUTE IMMEDIATE 'ALTER INDEX tdr_etl_ct_zone_auths_n1 UNUSABLE';  -- 07/07/16
        FOR a IN attaches LOOP

            IF (make_changes_i = 1) THEN
                -- Exclude any Invalid Authorities - crapp-2244 --
                INSERT INTO tdr_etl_ct_zone_authorities
                    (merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name)
                    (
                    SELECT merchant_id, NVL(primary_key, l_id+rownum) primary_key, zone_1_id, zone_1_name,
                           zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, a.authority
                    FROM (
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND zt.zone_3_name IS NOT NULL
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                            UNION
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   tdr_etl_ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                         )
                    WHERE a.authority NOT IN (SELECT DISTINCT gis_name FROM content_repo.gis_zone_juris_auths_tmp)  -- crapp-3363
                    );
            ELSE
                INSERT INTO tdr_etl_ct_zone_authorities
                    (merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name)
                    (
                    SELECT merchant_id, NVL(primary_key, l_id+rownum) primary_key, zone_1_id, zone_1_name,
                           zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, a.authority
                    FROM (
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND zt.zone_3_name IS NOT NULL
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                            UNION
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   tdr_etl_ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                         )
                    );
            END IF;

            SELECT MAX(primary_key)
            INTO l_id
            FROM tdr_etl_ct_zone_authorities;
        END LOOP;
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX tdr_etl_ct_zone_auths_n1 REBUILD';  -- 07/07/16
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'tdr_etl_ct_zone_authorities', cascade => TRUE); -- CRAPP-3174
        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES',' - Process attaches - end','GIS',NULL,NULL);

        etl_proc_log_p('GIS_ETL.BUILD_TB_ZONE_AUTHORITIES','Procedure - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);
    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'Build_TB_Zone_Authorities timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'Build_TB_Zone_Authorities error - '||SQLERRM);
    END build_tb_zone_authorities;



    -- ***************** --
    --     DET_UPDATE    --
    -- ***************** --



    FUNCTION get_zone_id(merch_id_i IN NUMBER , state_i IN VARCHAR2, county_i IN VARCHAR2, city_i IN VARCHAR2, postcode_i IN VARCHAR2, plus4_i IN VARCHAR)
    RETURN NUMBER
    IS
        l_ret NUMBER;
    BEGIN

        WITH ztree AS
            (
            SELECT zone_3_name,
                   coalesce(zone_7_id, zone_6_id, zone_5_id, zone_4_id, zone_3_id, zone_2_id) zone_id
            FROM   ct_zone_tree
            WHERE  zone_3_name = state_i
            AND nvl(zone_4_name,'ZONE_4_NAME') = nvl(county_i,'ZONE_4_NAME')
            AND nvl(zone_5_name,'ZONE_5_NAME') = nvl(city_i,'ZONE_5_NAME')
            AND nvl(zone_6_name,'ZONE_6_NAME') = nvl(postcode_i,'ZONE_6_NAME')
            AND nvl(zone_7_name,'ZONE_7_NAME') = nvl(plus4_i,'ZONE_7_NAME')
            AND merchant_id = merch_id_i
            ),
        changes AS
            (
            SELECT state, id
            FROM   tdr_etl_us_zone_changes zc
            WHERE  state = state_i
            AND nvl(county,'ZONE_4_NAME')   = nvl(county_i,'ZONE_4_NAME')
            AND nvl(city,'ZONE_5_NAME')     = nvl(city_i,'ZONE_5_NAME')
            AND nvl(postcode,'ZONE_6_NAME') = nvl(postcode_i,'ZONE_6_NAME')
            AND nvl(plus4,'ZONE_7_NAME')    = nvl(plus4_i,'ZONE_7_NAME')
            AND change_type = 'Add'
            ),
         changes2 AS
            (
            SELECT state, MAX(id) id
            FROM   tdr_etl_us_zone_changes zc
            WHERE  state = state_i
            AND nvl(county,'ZONE_4_NAME')   = nvl(county_i,'ZONE_4_NAME')
            AND nvl(city,'ZONE_5_NAME')     = nvl(city_i,'ZONE_5_NAME')
            AND nvl(postcode,'ZONE_6_NAME') = nvl(postcode_i,'ZONE_6_NAME')
            AND change_type = 'Add'
            GROUP BY state
            )
         SELECT COALESCE(Z1, Z2, Z3)
         INTO l_ret
         FROM (
                SELECT 'ztree' tbl, zone_id
                FROM ztree
                UNION
                SELECT 'changes' tbl, id
                FROM changes
                UNION
                SELECT 'changes2' tbl, id
                FROM changes2
              ) z pivot (MIN(zone_id) FOR tbl IN ('ztree' Z1, 'changes' Z2, 'changes2' Z3));

        l_ret := (l_ret||'.1'); -- 04/03/15 - moved decimal to end of number

        RETURN l_ret;
    END get_zone_id;


    PROCEDURE compare_zone_trees(make_changes_i IN NUMBER) IS  -- 07/28/17 - crapp-3523

        l_state          VARCHAR2(25 CHAR);
        l_jobstate       VARCHAR2(25 CHAR);
        l_merch_id       NUMBER;
        l_zone_auth_id   NUMBER;
        l_parent_zone_id NUMBER;
        l_created_by     NUMBER := -204;
        l_primary_key    NUMBER;
        l_zone_id        NUMBER;
        l_next_id        NUMBER;
        l_rec            NUMBER := 0;

        esql             VARCHAR2(50 CHAR);

        -- 01/27/16 crapp-2244 --
        l_msg            VARCHAR2(4000 CHAR);
        l_stcode         VARCHAR2(2 CHAR);
        l_auths          NUMBER := 0;

        TYPE t_pvw_tb_zones IS TABLE OF pvw_tb_zones%ROWTYPE;
        v_pvw_tb_zones t_pvw_tb_zones;

        CURSOR invalid_auths IS
            SELECT DISTINCT state_code, gis_name
            FROM   content_repo.gis_zone_juris_auths_tmp    -- crapp-3363
            ORDER BY gis_name;
        -------------------------

        CURSOR zone_deletes(state_i IN VARCHAR2) IS
            SELECT ctz.primary_key, ctz.merchant_id
            FROM   ct_zone_tree ctz
                JOIN (  SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   ct_zone_tree
                        WHERE  zone_3_name = state_i
                        MINUS
                        SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   tdr_etl_ct_zone_tree
                     ) d ON ctz.zone_3_name = d.state
                         AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                         AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                         AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                         AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                         AND ctz.merchant_id = d.merchant_id
            WHERE ctz.zone_3_name = state_i;    -- crapp-3523, added

        CURSOR zone_updates(state_i IN VARCHAR2) IS
            SELECT primary_key, zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4,
                   code_2char, code_3char, code_fips, default_flag, terminator_flag, reverse_flag, range_min, range_max,
                   CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                        WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                   CASE WHEN zone_4_id IS NULL THEN zone_2_id WHEN zone_5_id IS NULL THEN zone_3_id WHEN zone_6_id IS NULL THEN zone_4_id
                        WHEN zone_7_id IS NULL THEN zone_5_id ELSE zone_6_id END parent_zone_id,
                   COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name) name, merchant_id
            FROM   tdr_etl_ct_zone_tree
            WHERE  zone_3_name = state_i
                   AND primary_key IS NOT NULL
            MINUS
            SELECT primary_key, zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4,
                   code_2char, code_3char, code_fips, default_flag, terminator_flag, reverse_flag, range_min, range_max,
                   CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                        WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                   CASE WHEN zone_4_id IS NULL THEN zone_2_id WHEN zone_5_id IS NULL THEN zone_3_id WHEN zone_6_id IS NULL THEN zone_4_id
                        WHEN zone_7_id IS NULL THEN zone_5_id ELSE zone_6_id END parent_zone_id,
                   COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name), merchant_id
            FROM   ct_zone_tree
            WHERE  zone_3_name = state_i;

        CURSOR zone_adds IS
            SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4,
                   code_2char, code_3char, code_fips, default_flag, terminator_flag, reverse_flag, range_min, range_max,
                   CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                        WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                   COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name) name
            FROM   tdr_etl_ct_zone_tree a
            WHERE  primary_key IS NULL
                   AND NOT EXISTS (SELECT 1
                                   FROM   tdr_etl_ct_zone_tree u
                                   WHERE  a.zone_3_name = u.zone_3_name
                                          AND a.zone_4_name = u.zone_4_name
                                          AND NVL(a.zone_5_name, 'NULL zone5') = NVL(u.zone_5_name, 'NULL zone5')
                                          AND NVL(a.zone_6_name, 'NULL zone6') = NVL(u.zone_6_name, 'NULL zone6')
                                          AND NVL(a.zone_7_name, 'NULL zone7') = NVL(u.zone_7_name, 'NULL zone7')
                                          AND u.primary_key IS NOT NULL -- updates
                                  )
            ORDER BY zone_level_id DESC, a.zone_3_name, a.zone_4_name, a.zone_5_name, a.zone_6_name, a.code_fips;  -- added 08/20/15

        CURSOR zone_add_levels IS
            SELECT DISTINCT zone_level_id
            FROM (
                 SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode,
                        code_fips, zone_7_name plus4,
                        CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                             WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                        COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name) name
                 FROM   tdr_etl_ct_zone_tree a
                 WHERE  a.zone_3_name = l_state
                        AND primary_key IS NULL
                        AND NOT EXISTS (SELECT 1
                                        FROM   tdr_etl_ct_zone_tree u
                                        WHERE  a.zone_3_name = u.zone_3_name
                                               AND a.zone_4_name = u.zone_4_name
                                               AND NVL(a.zone_5_name, 'NULL zone5') = NVL(u.zone_5_name, 'NULL zone5')
                                               AND NVL(a.zone_6_name, 'NULL zone6') = NVL(u.zone_6_name, 'NULL zone6')
                                               AND NVL(a.zone_7_name, 'NULL zone7') = NVL(u.zone_7_name, 'NULL zone7')
                                               AND u.primary_key IS NOT NULL -- updates
                                       )
                 )
            ORDER BY zone_level_id DESC;

        CURSOR zone_orphans IS
            SELECT z.zone_id, z.NAME, z.parent_zone_id, o.zone_id orig_zone_id, o.NAME orig_name, o.parent,  o.parent_fips
            FROM   tb_zones z
                JOIN ( SELECT zone_id, NAME, parent_zone_id, code_fips, SUBSTR(code_fips, 11, 5) parent, SUBSTR(code_fips, 1, 15) parent_fips
                       FROM   tb_zones
                       WHERE  zone_id IN ( SELECT z1.zone_id
                                           FROM   tb_zones z1
                                           WHERE  z1.name != 'WORLD'
                                                  AND NOT EXISTS (
                                                                  SELECT 1
                                                                  FROM   tb_zones z2
                                                                  WHERE  z2.zone_id = z1.parent_zone_id
                                                                         AND z2.merchant_id = z1.merchant_id
                                                                 )
                                         )
                     ) o ON z.NAME = o.parent
                            AND z.code_fips = o.parent_fips;

        CURSOR detaches(state_i IN VARCHAR2) IS
            SELECT ctz.primary_key, d.authority_id, d.authority_name
            FROM   ct_zone_tree ctz
                JOIN (
                        SELECT z.*, a.authority_id
                        FROM   (
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   ct_zone_authorities
                                WHERE  zone_3_name = state_i
                                MINUS
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   tdr_etl_ct_zone_authorities
                               ) z
                               LEFT JOIN tb_authorities a ON (    z.authority_name = a.NAME
                                                              AND z.merchant_id = a.merchant_id
                                                             )
                        WHERE z.state = (SELECT DISTINCT zone_3_name FROM tdr_etl_ct_zone_authorities)  -- 08/13/15 - added to check for records to detach
                     ) d ON (
                                 ctz.zone_3_name = d.state
                             AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                             AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                             AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                             AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                             AND ctz.merchant_id = d.merchant_id
                            )
            WHERE ctz.zone_3_name = state_i   -- crapp-3523
            UNION -- Exceptions if not found in ct_zone_tree
            SELECT ctz.primary_key, d.authority_id, d.authority_name
            FROM   ct_zone_authorities ctz
                JOIN (
                        SELECT z.*, a.authority_id
                        FROM   (
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   ct_zone_authorities
                                WHERE  zone_3_name = state_i
                                MINUS
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   tdr_etl_ct_zone_authorities
                               ) z
                               LEFT JOIN tb_authorities a ON (    z.authority_name = a.NAME
                                                              AND z.merchant_id = a.merchant_id
                                                             )
                        WHERE z.state = (SELECT DISTINCT zone_3_name FROM tdr_etl_ct_zone_authorities)  -- 08/13/15 - added to check for records to detach
                     ) d ON (
                                 ctz.zone_3_name = d.state
                             AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                             AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                             AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                             AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                             AND ctz.authority_name = d.authority_name
                            )
            WHERE ctz.zone_3_name = state_i;   -- crapp-3523

        CURSOR attaches(state_i IN VARCHAR2) IS
            SELECT z.*
                   , a.authority_id
                   , gis_etl.get_zone_id(z.merchant_id, state, county, city, postcode, plus4) zone_id    -- crapp-3523
            FROM   (
                    SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                           , authority_name, merchant_id
                    FROM   tdr_etl_ct_zone_authorities
                    WHERE  zone_3_name = state_i    -- crapp-3523
                    MINUS
                    SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                           , authority_name, merchant_id
                    FROM   ct_zone_authorities
                    WHERE  zone_3_name = state_i
                   ) z
                   LEFT JOIN tb_authorities a ON (z.authority_name = a.NAME
                                                  AND z.merchant_id = a.merchant_id);

        CURSOR ids IS
            SELECT DISTINCT * FROM tdr_etl_us_zone_ids WHERE tbl_name = 'TB_ZONES';

    BEGIN
        SELECT DISTINCT zone_3_name
        INTO l_state
        FROM content_repo.gis_ztree_tmp;

        -- 01/27/16 crapp-2244 --
        SELECT code
        INTO   l_stcode
        FROM   tb_states
        WHERE NAME = l_state;

        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES','Process - start, make_changes_i = '||make_changes_i||' - '||l_stcode||'','GIS',NULL,NULL);

        SELECT merchant_id
        INTO l_merch_id
        FROM tb_merchants
        WHERE name = g_tdp;

        IF (make_changes_i = 1) THEN
            -- 04/09/15 -- Disable scheduled user jobs to refresh CT_ZONE_TREE and CT_ZONE_AUTHORITIES (runs every 15 minutes)

            LOOP    -- 12/02/15 crapp-2185
                SELECT state
                INTO   l_jobstate
                FROM   user_scheduler_jobs
                WHERE  job_name = 'UPDATE_CT_ZONE_TREE';

                EXIT WHEN l_jobstate IN ('SCHEDULED','DISABLED');
            END LOOP;
            dbms_scheduler.DISABLE('UPDATE_CT_ZONE_TREE');

            LOOP    -- 12/02/15 crapp-2185
                SELECT state
                INTO   l_jobstate
                FROM   user_scheduler_jobs
                WHERE  job_name = 'UPDATE_CT_ZONE_AUTHORITIES';

                EXIT WHEN l_jobstate IN ('SCHEDULED','DISABLED');
            END LOOP;
            dbms_scheduler.DISABLE('UPDATE_CT_ZONE_AUTHORITIES');
        ELSE
            EXECUTE IMMEDIATE 'TRUNCATE TABLE pvw_tb_zones DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE pvw_tb_zone_authorities DROP STORAGE';
        END IF;

        -- Process Zone Authority Detaches
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Authority detaches - start','GIS',NULL,NULL);
        l_rec := 0;
        FOR d in detaches(l_state) LOOP
            IF (make_changes_i = 1) THEN
                BEGIN
                    DELETE FROM tb_zone_authorities
                    WHERE  zone_id = d.primary_key
                           AND authority_id = d.authority_id;     -- added 04/09/15

                EXCEPTION WHEN no_data_found THEN
                    --if the Zone_ID or Authority_ID can't be found, delete whatever is in ct_zone_Authorities
                    DELETE FROM ct_zone_authorities
                    WHERE  primary_key = d.primary_key;
                END;
            ELSE
                BEGIN
                    INSERT INTO pvw_tb_zone_authorities (ZONE_ID, AUTHORITY_ID, AUTHORITY_NAME, STATE_CODE) -- 03/14/16 - crapp-2448 - Added State_Code
                        VALUES ( (d.primary_key * -1), d.authority_id, d.authority_name, l_stcode);

                    -- crapp-3523 - added to commit every 1000 records - Preview only --
                    l_rec := l_rec + 1;
                    IF l_rec >= 1000 THEN
                        COMMIT;
                        l_rec := 0;
                    END IF;
                END;
            END IF;
        END LOOP;

        IF (make_changes_i = 0) THEN -- Commit remaining records on Preview only --
            COMMIT;
        END IF;
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Authority detaches - end','GIS',NULL,NULL);


        -- Process Zone Tree Deletes
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Tree deletes - start','GIS',NULL,NULL);

        IF (make_changes_i = 1) THEN
            FOR d in zone_deletes(l_state) LOOP
                DELETE FROM tb_zones
                WHERE zone_id = d.primary_key;
            END LOOP;
        ELSE
            -- 08/12/16 - changed to bulk insert for performance improvements
            SELECT ctz.primary_key zone_id
                   , '.' name
                   , NULL parent_zone_id
                   , ctz.merchant_id
                   , NULL zone_level_id
                   , NULL eu_zone_as_of_date
                   , NULL reverse_flag
                   , NULL terminator_flag
                   , NULL default_flag
                   , NULL range_min
                   , NULL range_max
                   , NULL tax_parent_zone_id
                   , NULL code_2char
                   , NULL code_3char
                   , NULL code_iso
                   , NULL code_fips
                   , NULL synchronization_timestamp
            BULK COLLECT INTO v_pvw_tb_zones
            FROM   ct_zone_tree ctz
                JOIN (  SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   ct_zone_tree ct
                        WHERE  zone_3_name = l_state
                        MINUS
                        SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   tdr_etl_ct_zone_tree
                        WHERE  zone_3_name = l_state
                     ) d ON ctz.zone_3_name = d.state
                         AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                         AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                         AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                         AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                         AND ctz.merchant_id = d.merchant_id;

            FORALL i IN v_pvw_tb_zones.first..v_pvw_tb_zones.last
                INSERT INTO pvw_tb_zones
                VALUES v_pvw_tb_zones(i);
            COMMIT;

            v_pvw_tb_zones := t_pvw_tb_zones();
        END IF;
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Tree deletes - end','GIS',NULL,NULL);


        -- Process Zone Tree Updates
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Tree updates - start','GIS',NULL,NULL);
        l_rec := 0;
        FOR u in zone_updates(l_state) LOOP
            IF (make_changes_i = 1) THEN

                UPDATE tb_zones
                SET    NAME              = u.NAME
                       ,zone_level_id    = u.zone_level_id
                       ,code_2char       = u.code_2char
                       ,code_3char       = u.code_3char
                       ,code_fips        = u.code_fips
                       ,default_flag     = u.default_flag
                       ,terminator_flag  = u.terminator_flag
                       ,reverse_flag     = u.reverse_flag
                       ,range_min        = u.range_min
                       ,range_max        = u.range_max
                       ,last_updated_by  = l_created_by     -- added 08/06/15
                WHERE  zone_id = u.primary_key;
            ELSE
                INSERT INTO pvw_tb_zones (zone_id, parent_zone_id, merchant_id, name, zone_level_id, code_2char,
                        code_3char, code_fips, default_flag, reverse_flag, terminator_flag, range_min, range_max)
                VALUES (u.primary_key, u.parent_zone_id, u.merchant_id, u.name, u.zone_level_id, u.code_2char,
                        u.code_3char, u.code_fips, u.default_flag, u.reverse_flag, u.terminator_flag, u.range_min, u.range_max);

                -- crapp-3523 - added to commit every 1000 records - Preview only --
                l_rec := l_rec + 1;
                IF l_rec >= 1000 THEN
                    COMMIT;
                    l_rec := 0;
                END IF;
            END IF;
        END LOOP;

        IF (make_changes_i = 0) THEN -- Commit remaining records on Preview only --
            COMMIT;
        END IF;
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Tree updates - end','GIS',NULL,NULL);


        IF (make_changes_i = 1) THEN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_us_zone_ids DROP STORAGE'; -- 03/12/15
            l_next_id := pk_tb_zones.nextval;   -- crapp-2172
        END IF;

        -- Process Zone Tree Adds
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Tree adds - start','GIS',NULL,NULL);
        FOR l in zone_add_levels LOOP <<zone_add_level_loop>>

            l_rec := 0;
            FOR a in zone_adds LOOP <<zone_add_loop>>
                IF l.zone_level_id = a.zone_level_id THEN
                    -- 09/11/15 crapp-2050 - added FLOOR statements --
                    IF (a.zone_level_id = -5) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,NULL,NULL,NULL,NULL));
                    ELSIF (a.zone_level_id = -6) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,a.county,NULL,NULL,NULL));
                    ELSIF (a.zone_level_id = -7) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,a.county,a.city,NULL,NULL));
                    ELSIF (a.zone_level_id = -8) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,a.county,a.city,a.postcode,NULL));
                    END IF;

                    l_zone_id := get_zone_id(l_merch_id,a.state,a.county,a.city,a.postcode,a.plus4);

                    IF (make_changes_i = 1) THEN
                        dbms_output.put_line(l_zone_id ||' - '|| a.state ||' - '|| a.county ||' - '|| a.city ||' - '|| a.postcode ||' - '|| a.plus4 ||' - '|| l_parent_zone_id);

                        -- Set next ID --
                        IF l_zone_id - TRUNC(l_zone_id) = 0.1 THEN

                            l_next_id := pk_tb_zones.nextval;   -- crapp-2172

                            -- store id change -- 03/12/15
                            INSERT INTO tdr_etl_us_zone_ids
                                (tbl_name, new_primary_key, old_primary_key)
                                VALUES('TB_ZONES', l_next_id, l_zone_id);

                            l_zone_id := l_next_id;
                            dbms_output.put_line(l_zone_id);
                        END IF;

                        INSERT INTO tb_zones (zone_id, parent_zone_id, merchant_id, name, zone_level_id, code_2char,
                                code_3char, code_fips, default_flag, reverse_flag, terminator_flag, range_min, range_max,
                                created_by, creation_date, last_updated_by, last_update_date)
                        VALUES (l_zone_id, l_parent_zone_id, l_merch_id,
                                a.name, a.zone_level_id, a.code_2char, a.code_3char, a.code_fips, a.default_flag, a.reverse_flag,
                                a.terminator_flag, a.range_min, a.range_max, l_created_by, SYSDATE, l_created_by, SYSDATE);
                    ELSE
                        INSERT INTO pvw_tb_zones (zone_id, parent_zone_id, merchant_id, name, zone_level_id, code_2char,
                                code_3char, code_fips, default_flag, reverse_flag, terminator_flag, range_min, range_max)
                        VALUES (l_zone_id, l_parent_zone_id, l_merch_id,
                                a.name, a.zone_level_id, a.code_2char, a.code_3char, a.code_fips, a.default_flag, a.reverse_flag,
                                a.terminator_flag, a.range_min, a.range_max);

                        -- crapp-3523 - added to commit every 1000 records - Preview only --
                        l_rec := l_rec + 1;
                        IF l_rec >= 1000 THEN
                            COMMIT;
                            l_rec := 0;
                        END IF;
                    END IF;
                END IF;
            END LOOP zone_add_loop;

            IF (make_changes_i = 0) THEN -- Commit remaining records on Preview only --
                COMMIT;
            END IF;


            IF (make_changes_i = 1) THEN
                FOR z IN ids LOOP
                    UPDATE tb_zones
                         SET  parent_zone_id = z.new_primary_key
                    WHERE parent_zone_id = z.old_primary_key;
                END LOOP;

                -- Update TAX_PARENT_ZONE_ID column -- 01/05/16
                etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES','   - '||l_stcode||' - Process DATAX_UTL_FKA_74 - start','GIS',NULL,NULL);
                    DATAX_UTL_FKA_74;

                    esql := 'ALTER TRIGGER dt_zones ENABLE';
                    EXECUTE IMMEDIATE esql;
                etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES','   - '||l_stcode||' - Process DATAX_UTL_FKA_74 - end','GIS',NULL,NULL);

                -- repopulate ct_update_zone_tree/ct_zone_authorities
                etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES','   - '||l_stcode||' - Process ct_update_zone_tree - start','GIS',NULL,NULL);
                    ct_update_zone_tree;
                etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES','   - '||l_stcode||' - Process ct_update_zone_tree - end','GIS',NULL,NULL);
            END IF;

        END LOOP zone_add_level_loop;
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Tree adds - end','GIS',NULL,NULL);


        -- Update Parent_Zone_IDs   -- 03/12/15
        IF (make_changes_i = 1) THEN
            etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Update CT Zone Tree - start','GIS',NULL,NULL);

            -- 08/17/15 - check for orphaned zones and fix
            FOR z IN zone_orphans LOOP
                dbms_output.put_line('OrigZoneID '||z.orig_zone_id||' OrigName '||z.orig_name||' ParentZoneID '||z.zone_id);

                UPDATE tb_zones
                    SET parent_zone_id = z.zone_id
                WHERE zone_id = z.orig_zone_id
                      AND NAME = z.orig_name;
            END LOOP;

            -- repopulate ct_update_zone_tree/ct_zone_authorities
            ct_update_zone_tree;

            l_zone_auth_id := pk_tb_zone_authorities.nextval;   -- crapp-2172
            etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Update CT Zone Tree - end','GIS',NULL,NULL);
        END IF;


        -- Process Zone Authority Attaches
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Authority attaches - start','GIS',NULL,NULL);
        l_rec := 0;
        FOR a in attaches(l_state) LOOP <<attach_loop>>
            IF (make_changes_i = 1) THEN

                BEGIN
                    l_zone_auth_id := pk_tb_zone_authorities.nextval;   -- crapp-2172

                    INSERT INTO tb_zone_authorities (zone_authority_id, zone_id, authority_id, created_by, creation_date,
                            last_updated_by, last_update_date)
                    (
                      SELECT l_zone_auth_id
                             , primary_key
                             , a.authority_id
                             , l_created_by  created_by
                             , SYSDATE       creation_date
                             , l_created_by  last_updated_by
                             , SYSDATE       last_update_date
                      FROM   ct_zone_tree
                      WHERE  zone_3_name = a.state
                             AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                             AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                             AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                             AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                             AND merchant_id = a.merchant_id
                             AND a.authority_id IS NOT NULL -- crapp-3636
                    );
                EXCEPTION WHEN no_data_found THEN
                    dbms_output.put_line('Record not found for Authority:'||a.authority_name||' or Zone:'||a.state||','||a.county||','||a.city||','||a.postcode||','||a.plus4);
                    RAISE;
                END;
            ELSE

                --l_zone_id := get_zone_id(a.merchant_id, a.state, a.county, a.city, a.postcode, a.plus4); -- crapp-3523, moved into cursor

                BEGIN   -- Updated 06/10/15 --
                     SELECT primary_key
                     INTO   l_primary_key
                     FROM   ct_zone_tree
                     WHERE  zone_3_name = a.state
                            AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                            AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                            AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                            AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                            AND merchant_id = a.merchant_id;

                    INSERT INTO pvw_tb_zone_authorities (zone_id, authority_id, authority_name, state_code) -- 03/14/16 - crapp-2448 - Added State_Code
                        VALUES(l_primary_key, a.authority_id, a.authority_name, l_stcode);

                EXCEPTION WHEN no_data_found THEN
                    INSERT INTO pvw_tb_zone_authorities (zone_id, authority_id, authority_name, state_code) -- 03/14/16 - crapp-2448 - Added State_Code
                    (
                     SELECT NVL(primary_key, a.zone_id) -- crapp-3523, now using a.zone_id instead of l_zone_id
                            , a.authority_id
                            , a.authority_name
                            , l_stcode
                     FROM   tdr_etl_ct_zone_tree
                     WHERE  zone_3_name = a.state
                            AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                            AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                            AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                            AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                    );
                END;

                -- crapp-3523 - added to commit every 1000 records - Preview only --
                l_rec := l_rec + 1;
                IF l_rec >= 1000 THEN
                    COMMIT;
                    l_rec := 0;
                END IF;
            END IF;
        END LOOP attach_loop;

        IF (make_changes_i = 0) THEN -- Commit remaining records on Preview only --
            COMMIT;
        END IF;
        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Process Zone Authority attaches - end','GIS',NULL,NULL);


        IF (make_changes_i = 1) THEN
            etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Update CT Zone Authorities - start','GIS',NULL,NULL);

            -- Update Zone_ID if still has old_primary_key --
            FOR z IN ids LOOP       -- 08/17/15 crapp-1986
                UPDATE tb_zone_authorities
                     SET  zone_id = z.new_primary_key
                WHERE zone_id = z.old_primary_key;
            END LOOP;

            /*  -- 05/24/17 - Removed, causing invalid attachments --
            -- Check to make sure Preview table has current state data -- crapp-2448
            SELECT COUNT(*) cnt
            INTO   l_auths
            FROM   pvw_tb_zone_authorities
            WHERE  state_code = l_stcode;

            IF l_auths > 0 THEN
                -- Insert any missed Attachments from Preview -- 08/17/15 crapp-1986
                INSERT INTO tb_zone_authorities
                    (zone_id, authority_id, creation_date, created_by, last_update_date, last_updated_by)    -- crapp-2172, let trigger handle Zone_Authority_ID
                    (
                        SELECT new_primary_key, a.authority_id, SYSDATE cd, l_created_by cb, SYSDATE, l_created_by  -- mid+rownum
                        FROM  (
                                SELECT  DISTINCT i.new_primary_key, authority_name, authority_id  -- crapp-2172 - ,mid
                                FROM    v_pvw_tb_zone_auths za
                                        JOIN tdr_etl_us_zone_ids i ON (i.old_primary_key = za.zone_id)
                                WHERE   zone_id-FLOOR(zone_id) = .1
                                        AND za.authority_id IS NOT NULL
                                        AND za.zone_3_name = l_state
                                        AND za.state_code  = l_stcode   -- crapp-2448
                              ) b
                              JOIN tb_authorities a ON ( a.name = b.authority_name
                                                         AND a.merchant_id = 2
                                                       )
                        WHERE NOT EXISTS ( SELECT 1
                                           FROM   tb_zone_authorities ta
                                           WHERE  ta.zone_id = new_primary_key
                                                  AND ta.authority_id = a.authority_id
                                         )
                    );

                l_auths := 0;
            END IF;
            */

            -- repopulate ct_zone_authorities
            ct_update_zone_authorities;

            -- 04/09/15 -- Enable scheduled user jobs to refresh CT_ZONE_TREE and CT_ZONE_AUTHORITIES
            dbms_scheduler.ENABLE('UPDATE_CT_ZONE_TREE');
            dbms_scheduler.ENABLE('UPDATE_CT_ZONE_AUTHORITIES');

            etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES',' - '||l_stcode||' - Update CT Zone Authorities - end','GIS',NULL,NULL);
        END IF;

        -- 01/27/16 crapp-2244 --
        SELECT COUNT(*) cnt
        INTO   l_auths
        FROM   content_repo.gis_zone_juris_auths_tmp -- crapp-3363
        WHERE  state_code = l_stcode;

        IF l_auths > 0 THEN
            IF (make_changes_i = 1) THEN
                FOR i IN invalid_auths LOOP
                    IF l_msg IS NULL THEN
                        l_msg := 'Export ETL LOAD did not attach the following '||l_auths||' Authorities that were not Published: '||CHR(13)||i.gis_name;
                    ELSE
                        l_msg := l_msg ||CHR(13)|| i.gis_name;
                    END IF;
                    EXIT WHEN LENGTH(l_msg) > 3800;
                END LOOP;
            ELSE
                FOR i IN invalid_auths LOOP
                    IF l_msg IS NULL THEN
                        l_msg := 'Export ETL PREVIEW found the following '||l_auths||' Jurisdictions that were not Published: '||CHR(13)||i.gis_name;
                    ELSE
                        l_msg := l_msg ||CHR(13)|| i.gis_name;
                    END IF;
                    EXIT WHEN LENGTH(l_msg) > 3800;
                END LOOP;
            END IF;

            content_repo.gis.update_sched_task(stcode_i=>l_stcode, method_i=>'export', msg_i=>l_msg);
        END IF; -- end of crapp-2244 section
        COMMIT;

        etl_proc_log_p('GIS_ETL.COMPARE_ZONE_TREES','Process - end, make_changes_i = '||make_changes_i||' - '||l_stcode||'','GIS',NULL,NULL);
    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'Compare zone tree timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'Compare zone tree error - '||SQLERRM);
    END compare_zone_trees;

END;
/