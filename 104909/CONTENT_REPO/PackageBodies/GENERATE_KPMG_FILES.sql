CREATE OR REPLACE PACKAGE BODY content_repo."GENERATE_KPMG_FILES"
IS
   --SAM 12/22/2016 Added to refresh the table as it was stale
    PROCEDURE load_ua_area
    IS
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE kpmg_ua_area';

        EXECUTE IMMEDIATE
            'CREATE TABLE kpmg_ua_area
                AS
                SELECT DISTINCT /*+ PARALLEL(a, 8) */
                               unique_area, area_id, state_code
                  FROM vgeo_unique_areas2 a';

        EXECUTE IMMEDIATE
            'CREATE INDEX kpmg_ua_area_I1 ON kpmg_ua_area(STATE_CODE)';

        EXECUTE IMMEDIATE
            'CREATE INDEX kpmg_ua_area_I2 ON kpmg_ua_area(STATE_CODE, AREA_ID)';
    END;

/*
    PROCEDURE generate_zip_pt
    IS
        TYPE array IS TABLE OF kpmg_zip_extract_pt%ROWTYPE;
            l_data       array;
            l_eligible   BOOLEAN;
            CURSOR cur ( state_code_i    VARCHAR2)
            IS SELECT /* parallel(s,6) */
 /*                     area_id,
                       zip,
                       SUBSTR (zip9, 6) plus4_range,
                       CASE WHEN override_rank > 0 THEN 'Y' ELSE 'N' END default_flag,
                       state_code
                  BULK COLLECT INTO l_data
                  FROM geo_usps_lookup s
                 WHERE state_code = state_code_i;
    BEGIN
        --EXECUTE IMMEDIATE 'truncate table kpmg_zip_extract_pt';
            FOR i
                IN (SELECT DISTINCT code
                    FROM sbxtax.tb_states
                    WHERE     us_state = 'Y'
                )
            LOOP
                OPEN cur (i.code);

                LOOP
                    FETCH cur   BULK COLLECT INTO l_data LIMIT 100000;

                    FORALL indx IN 1 .. l_data.COUNT
                        INSERT INTO kpmg_zip_extract_pt
                        VALUES l_data (indx);

                    COMMIT;
                    EXIT WHEN cur%NOTFOUND;
                    COMMIT;
                END LOOP;

                CLOSE cur;

                COMMIT;
            END LOOP;

        /*
        FOR i IN (SELECT DISTINCT code
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y')
        LOOP
            INSERT ALL
              INTO kpmg_zip_extract_pt
                SELECT area_id,
                       zip,
                       SUBSTR (zip9, 6) plus4_range,
                       CASE WHEN override_rank > 0 THEN 'Y' ELSE 'N' END
                           default_flag,
                       state_code
                  FROM geo_usps_lookup
                 WHERE state_code = i.code;

            COMMIT;
        END LOOP;
        */
/*
        DELETE FROM kpmg_zip_extract_pt
         WHERE     zip IN (65739,
                           65761,
                           71256,
                           71069,
                           13843)
               AND state_code = 'AR';
    END;
*/
    PROCEDURE load_zip5_zip4_data (stcode_i VARCHAR2, flag NUMBER DEFAULT 0)
    IS
        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE     us_state = 'Y'
                   AND code NOT IN (SELECT DISTINCT state_code
                                      FROM kpmg_zip_extract_pt3);

        vcnt   NUMBER;
    BEGIN
        vcnt := 0;

        EXECUTE IMMEDIATE 'ALTER INDEX KPMG_ZIP_EXTRACT_PT3_N1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX KPMG_ZIP_EXTRACT_PT3_I1 UNUSABLE';
        EXECUTE IMMEDIATE 'truncate table KPMG_ZIP_EXTRACT_PT3';

        IF flag = 1
        THEN
            EXECUTE IMMEDIATE 'truncate table kpmg_zip_dup_defaults';

            INSERT ALL INTO kpmg_zip_dup_defaults
                SELECT DISTINCT zip, default_flag
                  FROM kpmg_zip_extract_pt a
                 WHERE     zip IS NOT NULL
                       AND plus4_range IS NULL
                       AND default_flag = 'Y'
                GROUP BY zip, default_flag
                HAVING COUNT (DISTINCT area_id) > 1;
        END IF;


        FOR s IN states
        LOOP
            vcnt := vcnt + 1;

            IF flag = 1
            THEN
                EXECUTE IMMEDIATE 'drop table KPMG_ZIP_EXTRACT_PT2';

                execute immediate 'create table KPMG_ZIP_EXTRACT_PT2 as
                    SELECT a.*, '''||s.state_code||''' state_code, ''Y'' default_flag
                      FROM (SELECT area_id, zip, COUNT (plus4_range) zip_cnt
                              FROM (SELECT DISTINCT *
                                      FROM kpmg_zip_extract_pt
                                     WHERE state_code = '''||s.state_code||'''
                                           AND zip IN
                                                   (SELECT DISTINCT zip
                                                      FROM kpmg_zip_dup_defaults)
                                           AND area_id IS NOT NULL
                                           AND plus4_range IS NOT NULL
                                           AND default_flag = ''Y'')
                            GROUP BY area_id, zip) a';

                DECLARE
                    vcnt   NUMBER;
                BEGIN
                    FOR i IN (SELECT zip, zip_cnt, COUNT (DISTINCT area_id)
                              FROM kpmg_zip_extract_pt2
                              WHERE state_code = s.state_code
                              GROUP BY zip, zip_cnt
                              HAVING COUNT (DISTINCT area_id) > 1)
                    LOOP
                        SELECT MAX (zip_cnt)
                          INTO vcnt
                          FROM kpmg_zip_extract_pt2
                         WHERE zip = i.zip;

                        IF vcnt = i.zip_cnt
                        THEN
                            UPDATE kpmg_zip_extract_pt2
                               SET default_flag = 'N'
                             WHERE     zip = i.zip
                                   AND zip_cnt = i.zip_cnt
                                   AND area_id IN
                                           (SELECT area_id
                                              FROM (SELECT area_id,
                                                           MIN (plus4_range)
                                                               plus4_range
                                                      FROM kpmg_zip_extract_pt
                                                     WHERE     zip = i.zip
                                                           AND state_code =
                                                                   s.state_code
                                                           AND area_id IN
                                                                   (SELECT DISTINCT
                                                                           area_id
                                                                      FROM kpmg_zip_extract_pt2
                                                                     WHERE     zip =
                                                                                   i.zip
                                                                           AND zip_cnt =
                                                                                   i.zip_cnt)
                                                    GROUP BY area_id
                                                    ORDER BY plus4_range DESC)
                                             WHERE ROWNUM = 1);
                        END IF;

                        IF vcnt < i.zip_cnt
                        THEN
                            UPDATE kpmg_zip_extract_pt2
                               SET default_flag = 'N'
                             WHERE     zip = i.zip
                                   AND zip_cnt = i.zip_cnt
                                   AND default_flag = 'Y';
                        END IF;
                    END LOOP;
                END;


                COMMIT;

                INSERT ALL
                  INTO kpmg_zip_extract_pt3
                    SELECT DISTINCT area_id,
                                    zip,
                                    NVL (default_flag, 'N') default_flag,
                                    s.state_code
                      FROM kpmg_zip_extract_pt
                     WHERE     state_code = s.state_code
                           AND zip IS NOT NULL
                           AND area_id IS NOT NULL
                           AND plus4_range IS NULL
                           AND zip NOT IN (SELECT DISTINCT zip
                                             FROM kpmg_zip_extract_pt2)
                    UNION
                    SELECT DISTINCT a.area_id,
                                    a.zip,
                                    'N' default_flag,
                                    s.state_code
                      FROM kpmg_zip_extract_pt a
                     WHERE     state_code = s.state_code
                           AND a.zip IS NOT NULL
                           -- AND plus4_range IS NOT NULL
                           AND a.area_id IS NOT NULL
                           AND a.plus4_range IS NULL
                           AND (default_flag IS NULL OR default_flag = 'N')
                           AND zip IN (SELECT DISTINCT zip
                                         FROM kpmg_zip_extract_pt2)
                           AND a.area_id NOT IN
                                   (SELECT DISTINCT area_id
                                      FROM kpmg_zip_extract_pt2)
                    UNION
                    SELECT DISTINCT a.area_id,
                                    a.zip,
                                    'Y' default_flag,
                                    s.state_code
                      FROM kpmg_zip_extract_pt a
                           JOIN kpmg_zip_extract_pt2 b
                               ON (a.area_id = b.area_id AND a.zip = b.zip)
                     WHERE     a.state_code = s.state_code
                           AND a.zip IS NOT NULL
                           -- AND plus4_range IS NOT NULL
                           AND a.area_id IS NOT NULL
                           AND a.plus4_range IS NULL
                           AND b.default_flag = 'Y'
                           AND b.zip_cnt = (SELECT MAX (zip_cnt)
                                              FROM kpmg_zip_extract_pt2 c
                                             WHERE b.zip = c.zip)
                    UNION
                    SELECT DISTINCT a.area_id,
                                    a.zip,
                                    'N' default_flag,
                                    s.state_code
                      FROM kpmg_zip_extract_pt a
                           JOIN kpmg_zip_extract_pt2 b
                               ON (a.area_id = b.area_id AND a.zip = b.zip)
                     WHERE     a.state_code = s.state_code
                           AND a.zip IS NOT NULL
                           AND a.area_id IS NOT NULL
                           AND a.plus4_range IS NULL
                           AND b.default_flag = 'N';


                INSERT ALL INTO kpmg_zip_extract_pt3
                    SELECT DISTINCT area_id,
                                    zip,
                                    'N',
                                    s.state_code
                      FROM (SELECT DISTINCT area_id, zip
                              FROM kpmg_zip_extract_pt2
                             WHERE state_code = s.state_code
                            MINUS
                            SELECT DISTINCT area_id, zip
                              FROM kpmg_zip_extract_pt3
                             WHERE state_code = s.state_code);


                BEGIN
                    FOR i
                        IN (SELECT DISTINCT
                                   zip,
                                   default_flag,
                                   MIN (state_code) state_code
                            FROM kpmg_zip_extract_pt3
                            WHERE zip IS NOT NULL AND default_flag = 'Y'
                            GROUP BY zip, default_flag
                            HAVING COUNT (DISTINCT area_id) > 1)
                    LOOP
                        UPDATE kpmg_zip_extract_pt3
                           SET default_flag = 'N'
                         WHERE     zip = i.zip
                               AND default_flag = 'Y'
                               AND state_code != i.state_code;
                    END LOOP;
                END;

                COMMIT;

                DELETE FROM kpmg_zip_extract_pt3 a
                 WHERE     default_flag = 'N'
                       AND state_code = s.state_code
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM kpmg_zip_extract_pt b
                                 WHERE     a.area_id = b.area_id
                                       AND a.zip = b.zip
                                       AND a.state_code = b.state_code
                                       AND b.state_code = s.state_code
                                       AND b.default_flag = 'Y');
                COMMIT;
            END IF;
        END LOOP;

        COMMIT;

    END;

    PROCEDURE generate_zip_pt3
    IS
    BEGIN
        -- This code works for all states
        load_zip5_zip4_data ('ALL', 1);
    END;

/*
    PROCEDURE generate_zip_final
    IS
    BEGIN
        EXECUTE IMMEDIATE 'truncate table kpmg_zip5_final';

        FOR i IN (SELECT code statecode
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y')
        LOOP
            INSERT INTO kpmg_zip5_final
                SELECT DISTINCT j1.*
                  FROM kpmg_zip_extract_pt3 j1
                       JOIN kpmg_zip_extract_pt_1 j2
                           ON (    j1.area_id = j2.area_id
                               AND j1.zip = j2.zip
                               AND j1.state_code = j2.state_code
                               AND j2.default_flag = 'Y')
                 WHERE j1.state_code = i.statecode
                   AND j2.state_code = i.statecode;

            COMMIT;
        END LOOP;

        EXECUTE IMMEDIATE 'truncate table kpmg_zip4_final';

        FOR l IN (SELECT DISTINCT code statecode
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y'
                  ORDER BY 1)
        LOOP
            INSERT ALL
              INTO kpmg_zip4_final
                SELECT DISTINCT j2.*
                  FROM kpmg_zip_extract_pt3 j1
                       JOIN kpmg_zip_extract_pt_1 j2
                           ON (    j1.area_id = j2.area_id
                               AND j1.zip = j2.zip
                               AND j1.state_code = j2.state_code
                               AND j2.plus4_range IS NOT NULL
                               AND j2.default_flag = 'Y')
                 WHERE j1.state_code = l.statecode
                   AND j2.state_code = l.statecode;

            COMMIT;
        END LOOP;

        COMMIT;
    END;
*/

    PROCEDURE replace_zip4_alpha
    IS
    BEGIN
        FOR l IN (SELECT DISTINCT code statecode
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y'
                  ORDER BY 1)
        LOOP
            BEGIN
                FOR i
                    IN (SELECT *
                        FROM kpmg_zip4_export
                        WHERE     state_code = l.statecode
                              AND ASCII (SUBSTR (plus4_range, 1, 1)) BETWEEN 65
                                                                         AND 90
                              AND plus4_range IS NOT NULL
                              AND default_flag = 'Y')
                LOOP
                    IF i.plus4_range = 'FOUR'
                    THEN
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9999'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    ELSIF i.plus4_range = 'FOU1'
                    THEN
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9997'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    ELSIF i.plus4_range = 'FOU2'
                    THEN
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9996'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    ELSIF i.plus4_range = 'FOU3'
                    THEN
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9995'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    ELSIF i.plus4_range = 'FOU4'
                    THEN
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9994'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    ELSIF i.plus4_range LIKE 'W%'
                    THEN
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9993'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    ELSE
                        UPDATE kpmg_zip4_export
                           SET plus4_range = '9992'
                         WHERE     state_code = l.statecode
                               AND zip = i.zip
                               AND plus4_range = i.plus4_range
                               AND area_id = i.area_id
                               AND default_flag = i.default_flag;
                    END IF;
                END LOOP;
            END;
        END LOOP;

        COMMIT;
    END;


    PROCEDURE remove_bad_data
    IS
    BEGIN
        FOR l IN (SELECT DISTINCT code statecode
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y'
                  ORDER BY 1)
        LOOP
            DELETE FROM kpmg_zip4_export a
             WHERE     state_code = l.statecode
                   AND (zip, plus4_range) IN
                           (SELECT zip, plus4_range
                              FROM (SELECT COUNT (DISTINCT area_id),
                                           zip,
                                           plus4_range
                                      FROM (SELECT /*+ parallel(z4,8) */*
                                              FROM kpmg_zip4_export z4
                                             WHERE     plus4_range
                                                           IS NOT NULL
                                                   AND state_code =
                                                           l.statecode)
                                     WHERE plus4_range IS NOT NULL
                                    GROUP BY zip, plus4_range
                                    HAVING COUNT (DISTINCT area_id) > 1))
                   AND EXISTS
                           (SELECT 1
                              FROM kpmg_zip5_export b
                             WHERE     a.area_id = b.area_id
                                   AND state_code = l.statecode
                                   AND a.zip = b.zip
                                   AND b.default_flag = 'N');
        END LOOP;

        COMMIT;
    END;

PROCEDURE generate_final_zip_tables
IS
BEGIN

DECLARE
    vcnt   NUMBER;

    CURSOR states
    IS
        SELECT code state_code
          FROM sbxtax.tb_states
         WHERE us_state = 'Y'
           order by 1;
BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE KPMG_ZIP5_EXPORT';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE KPMG_ZIP4_EXPORT';
    EXECUTE IMMEDIATE 'truncate table kpmg_export_areas_file';

    FOR s IN states
    LOOP
        EXECUTE IMMEDIATE 'drop table kpmg_zip_extract_pt';

        EXECUTE IMMEDIATE
               'create table kpmg_zip_extract_pt as
                    SELECT /* parallel(s,6) */
                                        area_id,
                                           zip,
                                           SUBSTR (zip9, 6) plus4_range,
                                           CASE WHEN override_rank > 0 THEN ''Y'' ELSE ''N'' END default_flag,
                                           state_code
                                      FROM geo_usps_lookup s
                                     WHERE state_code = '''
                                || s.state_code
                                || '''';

        EXECUTE IMMEDIATE 'truncate table kpmg_zip_dup_defaults';

        IF S.STATE_CODE = 'AR'
        THEN
            DELETE FROM kpmg_zip_extract_pt
             WHERE     zip IN (65739,
                               65761,
                               71256,
                               71069,
                               13843)
                   AND state_code = 'AR';
        END IF;

        INSERT ALL
          INTO kpmg_zip_dup_defaults
            SELECT DISTINCT zip, default_flag
              FROM kpmg_zip_extract_pt
             WHERE     zip IS NOT NULL
                   AND plus4_range IS NULL
                   AND default_flag = 'Y'
            GROUP BY zip, default_flag
            HAVING COUNT (DISTINCT area_id) > 1;

        EXECUTE IMMEDIATE 'drop table KPMG_ZIP_EXTRACT_PT2';

        EXECUTE IMMEDIATE
               'create table KPMG_ZIP_EXTRACT_PT2 as
                     SELECT a.*, '''
                            || s.state_code
                            || ''' state_code, ''Y'' default_flag
                       FROM (SELECT area_id, zip, COUNT (plus4_range) zip_cnt
                               FROM (SELECT DISTINCT *
                                       FROM kpmg_zip_extract_pt
                                      WHERE     state_code = '''
                            || s.state_code
                            || '''
                                            AND zip IN
                                                    (SELECT DISTINCT zip
                                                       FROM kpmg_zip_dup_defaults)
                                            AND area_id IS NOT NULL
                                            AND plus4_range IS NOT NULL
                                            AND default_flag = ''Y'')
                             GROUP BY area_id, zip) a';


        FOR i IN (SELECT zip, zip_cnt, COUNT (DISTINCT area_id)
                  FROM kpmg_zip_extract_pt2
                  WHERE state_code = s.state_code
                  GROUP BY zip, zip_cnt
                  HAVING COUNT (DISTINCT area_id) > 1)
        LOOP
            SELECT MAX (zip_cnt)
              INTO vcnt
              FROM kpmg_zip_extract_pt2
             WHERE zip = i.zip;

            IF vcnt = i.zip_cnt
            THEN
                UPDATE kpmg_zip_extract_pt2
                   SET default_flag = 'N'
                 WHERE     zip = i.zip
                       AND zip_cnt = i.zip_cnt
                       AND area_id IN
                               (SELECT area_id
                                  FROM (SELECT area_id,
                                               MIN (plus4_range) plus4_range
                                          FROM kpmg_zip_extract_pt
                                         WHERE     zip = i.zip
                                               AND state_code = s.state_code
                                               AND area_id IN
                                                       (SELECT DISTINCT
                                                               area_id
                                                          FROM kpmg_zip_extract_pt2
                                                         WHERE     zip =
                                                                       i.zip
                                                               AND zip_cnt =
                                                                       i.zip_cnt)
                                        GROUP BY area_id
                                        ORDER BY plus4_range DESC)
                                 WHERE ROWNUM = 1);
            END IF;

            IF vcnt < i.zip_cnt
            THEN
                UPDATE kpmg_zip_extract_pt2
                   SET default_flag = 'N'
                 WHERE     zip = i.zip
                       AND zip_cnt = i.zip_cnt
                       AND default_flag = 'Y';
            END IF;
        END LOOP;


        INSERT ALL
          INTO kpmg_zip_extract_pt3
            SELECT DISTINCT area_id,
                            zip,
                            NVL (default_flag, 'N') default_flag,
                            s.state_code
              FROM kpmg_zip_extract_pt
             WHERE     state_code = s.state_code
                   AND zip IS NOT NULL
                   AND area_id IS NOT NULL
                   AND plus4_range IS NULL
                   AND zip NOT IN (SELECT DISTINCT zip
                                     FROM kpmg_zip_extract_pt2)
            UNION
            SELECT DISTINCT a.area_id,
                            a.zip,
                            'N' default_flag,
                            s.state_code
              FROM kpmg_zip_extract_pt a
             WHERE     state_code = s.state_code
                   AND a.zip IS NOT NULL
                   -- AND plus4_range IS NOT NULL
                   AND a.area_id IS NOT NULL
                   AND a.plus4_range IS NULL
                   AND (default_flag IS NULL OR default_flag = 'N')
                   AND zip IN (SELECT DISTINCT zip
                                 FROM kpmg_zip_extract_pt2)
                   AND a.area_id NOT IN (SELECT DISTINCT area_id
                                           FROM kpmg_zip_extract_pt2)
            UNION
            SELECT DISTINCT a.area_id,
                            a.zip,
                            'Y' default_flag,
                            s.state_code
              FROM kpmg_zip_extract_pt a
                   JOIN kpmg_zip_extract_pt2 b
                       ON (a.area_id = b.area_id AND a.zip = b.zip)
             WHERE     a.state_code = s.state_code
                   AND a.zip IS NOT NULL
                   -- AND plus4_range IS NOT NULL
                   AND a.area_id IS NOT NULL
                   AND a.plus4_range IS NULL
                   AND b.default_flag = 'Y'
                   AND b.zip_cnt = (SELECT MAX (zip_cnt)
                                      FROM kpmg_zip_extract_pt2 c
                                     WHERE b.zip = c.zip)
            UNION
            SELECT DISTINCT a.area_id,
                            a.zip,
                            'N' default_flag,
                            s.state_code
              FROM kpmg_zip_extract_pt a
                   JOIN kpmg_zip_extract_pt2 b
                       ON (a.area_id = b.area_id AND a.zip = b.zip)
             WHERE     a.state_code = s.state_code
                   AND a.zip IS NOT NULL
                   AND a.area_id IS NOT NULL
                   AND a.plus4_range IS NULL
                   AND b.default_flag = 'N';


        INSERT ALL
          INTO kpmg_zip_extract_pt3
            SELECT DISTINCT area_id,
                            zip,
                            'N',
                            s.state_code
              FROM (SELECT DISTINCT area_id, zip
                      FROM kpmg_zip_extract_pt2
                     WHERE state_code = s.state_code
                    MINUS
                    SELECT DISTINCT area_id, zip
                      FROM kpmg_zip_extract_pt3
                     WHERE state_code = s.state_code);


        BEGIN
            FOR i
                IN (SELECT DISTINCT
                           zip, default_flag, MIN (state_code) state_code
                    FROM kpmg_zip_extract_pt3
                    WHERE zip IS NOT NULL AND default_flag = 'Y'
                    GROUP BY zip, default_flag
                    HAVING COUNT (DISTINCT area_id) > 1)
            LOOP
                UPDATE kpmg_zip_extract_pt3
                   SET default_flag = 'N'
                 WHERE     zip = i.zip
                       AND default_flag = 'Y'
                       AND state_code != i.state_code;
            END LOOP;

            COMMIT;
        END;


        DELETE FROM kpmg_zip_extract_pt3 a
         WHERE     default_flag = 'N'
               AND state_code = s.state_code
               AND NOT EXISTS
                       (SELECT 1
                          FROM kpmg_zip_extract_pt b
                         WHERE     a.area_id = b.area_id
                               AND a.zip = b.zip
                               AND a.state_code = b.state_code
                               AND b.state_code = s.state_code
                               AND b.default_flag = 'Y');

            DECLARE
            vcnt         NUMBER := 0;
            TYPE array_5 IS TABLE OF kpmg_zip5_export%ROWTYPE;
            TYPE array_4 IS TABLE OF kpmg_zip4_export%ROWTYPE;
            l_data_5       array_5;
            l_data_4       array_4;
            l_eligible   BOOLEAN;

            CURSOR cur
            IS
                SELECT DISTINCT b.*
                  FROM vkpmg_zip4_final a
                       JOIN vkpmg_zip5_final b
                           ON (    a.state_code = b.state_code
                               AND a.area_id = b.area_id
                               AND a.zip = b.zip)
                 WHERE a.state_code = s.state_code AND a.default_flag = 'Y';
            CURSOR cur1
            IS
                SELECT DISTINCT a.*
                  FROM vkpmg_zip4_final a
                       JOIN vkpmg_zip5_final b
                           ON (    a.state_code = b.state_code
                               AND a.area_id = b.area_id
                               AND a.zip = b.zip)
                 WHERE a.state_code = s.state_code AND a.default_flag = 'Y'
                ;
            BEGIN
            OPEN cur;
            LOOP
                FETCH cur BULK COLLECT INTO l_data_5 LIMIT 100000;

                FORALL indx IN 1 .. l_data_5.COUNT
                    INSERT INTO kpmg_zip5_export
                    VALUES l_data_5 (indx);
                    COMMIT;
                EXIT WHEN cur%NOTFOUND;

                COMMIT;
            END LOOP;

            CLOSE cur;
            OPEN cur1;
            LOOP
                FETCH cur1 BULK COLLECT INTO l_data_4 LIMIT 100000;

                FORALL indx IN 1 .. l_data_4.COUNT
                    INSERT INTO kpmg_zip4_export
                    VALUES l_data_4 (indx);
                    COMMIT;
                EXIT WHEN cur1%NOTFOUND;

                COMMIT;
            END LOOP;

            CLOSE cur1;
        END;

        INSERT ALL
          INTO kpmg_export_areas_file
            SELECT /*+ PARALLEL(d,8) */a.state_code a_state_code,
                   a.unique_area a_unique_area,
                   a.area_id a_area_id,
                   a.start_date a_start_date,
                   a.end_date a_end_date,
                   b.unique_area b_unique_area,
                   b.area_id b_area_id,
                   b.geo_area_key b_geo_area_key,
                   c.geo_area_key c_geo_area_key,
                   c.geo_area c_geo_area,
                   c.start_date c_start_date,
                   c.end_date c_end_date
              FROM kpmg_ext_area_detail a,
                   kpmg_ext_ua_polygon b,
                   kpmg_ext_geo_areas c,
                   vkpmg_zip5_final d
             WHERE     a.unique_area = b.unique_area
                   AND a.area_id = b.area_id
                   AND b.geo_area_key = c.geo_area_key
                   AND d.state_code = a.state_code
                   AND s.state_code = s.state_code
                   AND d.area_id = a.area_id;

        DELETE FROM kpmg_export_areas_file a
         WHERE a_state_code = s.state_code and NOT EXISTS
                   (SELECT 1
                      FROM vkpmg_zip5_final b
                     WHERE     a.a_state_code = b.state_code
                           AND a.a_area_id = b.area_id);

        COMMIT;
    END LOOP;
END;


    /*

        EXECUTE IMMEDIATE 'TRUNCATE TABLE kpmg_zip5_export';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE kpmg_zip4_export';
        execute immediate 'alter index KPMG_ZIP5_EXPORT_I1 unusable';
        execute immediate 'alter index KPMG_ZIP5_EXPORT_I2 unusable';

        FOR i IN (SELECT DISTINCT code
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y')
        LOOP
            INSERT ALL INTO kpmg_zip5_export
                SELECT DISTINCT b.*
                  FROM vkpmg_zip4_final a
                       JOIN vkpmg_zip5_final b
                           ON (    a.state_code = b.state_code
                               AND a.area_id = b.area_id
                               AND a.zip = b.zip)
                 WHERE a.state_code = i.code AND a.default_flag = 'Y'
                ORDER BY b.area_id, b.zip;

            execute immediate 'alter index KPMG_ZIP5_EXPORT_I1 rebuild partition state_'||i.code||'';
            execute immediate 'alter index KPMG_ZIP5_EXPORT_I2 rebuild partition state_'||i.code||'';

            COMMIT;
        END LOOP;

        FOR i IN (SELECT DISTINCT code
                  FROM sbxtax.tb_states
                  WHERE     us_state = 'Y'
                        AND code NOT IN (SELECT DISTINCT state_code
                                         FROM kpmg_zip4_export)
                  ORDER BY 1)
        LOOP
            INSERT ALL
              INTO kpmg_zip4_export
                SELECT DISTINCT a.*
                  FROM vkpmg_zip4_final a
                       JOIN vkpmg_zip5_final b
                           ON (    a.state_code = b.state_code
                               AND a.area_id = b.area_id
                               AND a.zip = b.zip)
                 WHERE a.state_code = i.code AND a.default_flag = 'Y'
                ORDER BY a.zip, a.plus4_range, a.area_id;

            COMMIT;
        END LOOP;

    */


DELETE FROM kpmg_export_areas_file
         WHERE     a_state_code = 'NJ'
               AND a_area_id IN
                       (SELECT a_area_id
                          FROM (SELECT COUNT (a_unique_area),
                                       a_state_code,
                                       a_area_id
                                  FROM (SELECT DISTINCT
                                               a_state_code,
                                               a_unique_area,
                                               a_area_id
                                          FROM kpmg_export_areas_file a)
                                GROUP BY a_area_id, a_state_code
                                HAVING COUNT (a_unique_area) > 1))
               AND check_kpmg_atleast_3_bounds (a_unique_area) <= 1;


        DELETE FROM kpmg_export_areas_file
         WHERE     a_unique_area =
                       'NC-37-NORTH CAROLINA|NC-101-JOHNSTON|NC-74580-WILSONS MILLS|NC-74580-WILSONS MILLS'
               AND a_state_code = 'NC'
               AND a_area_id = '37-101-74580';

        DELETE FROM kpmg_export_areas_file
         WHERE a_area_id IN (SELECT DISTINCT a_area_id area_id
                               FROM kpmg_export_areas_file a
                              WHERE check_kpmg_atleast_3_bounds (
                                        a_unique_area) > 1
                             MINUS
                             SELECT DISTINCT area_id
                               FROM kpmg_zip5_export);

        DELETE FROM kpmg_export_areas_file
         WHERE check_kpmg_atleast_3_bounds (a_unique_area) <= 1;


        COMMIT;
    END;

    PROCEDURE perform_datachecks
    IS
    BEGIN
        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_aplha_zip4 (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_aplha_zip4 failed state slist is '
                || vfailed_states);
        END;

        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_inzip4_notin_zip5 (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_inzip4_notin_zip5 failed state slist is '
                || vfailed_states);
        END;

        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck1_inzip4_notin_zip5 (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck1_inzip4_notin_zip5 failed state slist is '
                || vfailed_states);
        END;

        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_zip4_duparea (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_zip4_duparea failed state slist is '
                || vfailed_states);
        END;


        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_zip5_nodefault (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_zip5_nodefault failed state slist is '
                || vfailed_states);
        END;


        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck1_inzip5_notin_zip4 (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck1_inzip5_notin_zip4 failed state slist is '
                || vfailed_states);
        END;

        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_inzip5_notin_zip4 (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_inzip5_notin_zip4 failed state slist is '
                || vfailed_states);
        END;

        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_zip5_dupldefault (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_zip5_dupldefault failed state slist is '
                || vfailed_states);
        END;


        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_zip5_dupnondef (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_zip5_dupnondef failed state slist is '
                || vfailed_states);
        END;


        BEGIN
            datacheck_dup_taxes;
            DBMS_OUTPUT.put_line ('Dup taxes on the data set');
        END;


        DECLARE
            aplha_zip4_statecodes   VARCHAR2 (1000);
        BEGIN
            datacheck_dup_ua (aplha_zip4_statecodes);
            DBMS_OUTPUT.put_line (
                   'datacheck_dup_UA aplha_zip4_statecodes  value is '
                || aplha_zip4_statecodes);
        END;


        DECLARE
            vfailed_states   VARCHAR2 (5000);
        BEGIN
            datacheck_unique_area_zip5 (vfailed_states);
            DBMS_OUTPUT.put_line (
                   'datacheck_unique_area_zip5 failed state slist is '
                || vfailed_states);
        END;
    END;

    /* -- Old Versions

    -- Now: load_jurisdictions_table --
    PROCEDURE load_jurisdictions (extract_date_i DATE)
    IS
    BEGIN
        kpmg_export.load_jurisdictions (extract_date_i);
    END;

    -- Now: load_taxes_table --
    PROCEDURE load_taxes (extract_date_i DATE)
    IS
    BEGIN
        kpmg_export.load_taxes (extract_date_i);
    END;

    -- Now: load_juris_areas_table --
    PROCEDURE load_juris_areas
    IS
    BEGIN
        kpmg_export.load_juris_areas;
    END;
    */

    PROCEDURE load_geo_areas_table
    IS
        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE us_state = 'Y';
    BEGIN
        EXECUTE IMMEDIATE 'truncate table kpmg_ext_geo_areas';

        FOR s IN states
        LOOP
            INSERT ALL INTO kpmg_ext_geo_areas
                SELECT DISTINCT
                       REGEXP_REPLACE (
                           ASCIISTR (REPLACE (geo_area_key, '???', '''')),
                           '\\[[:xdigit:]]{4}',
                           ' ')
                           geo_area_key,
                       geo_area,
                       poly_startdate,
                       poly_enddate
                  FROM (SELECT /*+index(m geo_usps_mv_i1)*/
                                                                    --DISTINCT
                               a.area_id,
                               TO_CHAR (MAX (gp.start_date), 'mm/dd/yyyy')
                                   poly_startdate,
                               TO_CHAR (MAX (gp.end_date), 'mm/dd/yyyy')
                                   poly_enddate,
                               t.unique_area,
                               gp.geo_area_key,
                               gp.geo_area
                          FROM geo_usps_lookup a
                               JOIN geo_unique_areas ua
                                   ON (ua.area_id = a.area_id)
                               JOIN vunique_area_polygons uap
                                   ON (ua.rid = uap.unique_area_rid)
                               JOIN vgeo_polygons gp
                                   ON (    uap.poly_rid = gp.rid
                                       AND uap.poly_nkid = gp.nkid)
                               JOIN kpmg_ua_area t
                                   ON (    t.area_id = a.area_id
                                       AND t.state_code = a.state_code)
                         WHERE     a.state_code = s.state_code
                               AND a.end_date IS NULL
                               AND a.zip IS NOT NULL
                               AND a.zip9 IS NOT NULL
                        GROUP BY a.area_id,
                                 t.unique_area,
                                 gp.geo_area_key,
                                 gp.geo_area)
                -- WHERE ( poly_enddate IS NULL or poly_enddate < '01-Jan-1900' )
                ORDER BY geo_area_key;

            COMMIT;
        END LOOP;
    END;

    PROCEDURE load_area_polygon_table
    IS
        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE us_state = 'Y';
    BEGIN
        EXECUTE IMMEDIATE 'truncate table kpmg_ext_ua_polygon';

        FOR s IN states
        LOOP
            INSERT ALL INTO kpmg_ext_ua_polygon
                SELECT DISTINCT
                       REGEXP_REPLACE (
                           ASCIISTR (REPLACE (unique_area, '???', '''')),
                           '\\[[:xdigit:]]{4}',
                           ' ')
                           unique_area,
                       area_id,
                       REGEXP_REPLACE (
                           ASCIISTR (REPLACE (geo_area_key, '???', '''')),
                           '\\[[:xdigit:]]{4}',
                           ' ')
                           geo_area_key
                  FROM (SELECT /*+index(m geo_usps_mv_i1)*/
                              DISTINCT
                               a.area_id, t.unique_area, gp.geo_area_key
                          FROM geo_usps_lookup a
                               JOIN geo_unique_areas ua
                                   ON (ua.area_id = a.area_id)
                               JOIN vunique_area_polygons uap
                                   ON (ua.rid = uap.unique_area_rid)
                               JOIN vgeo_polygons gp
                                   ON (    uap.poly_rid = gp.rid
                                       AND uap.poly_nkid = gp.nkid)
                               JOIN kpmg_ua_area t
                                   ON (    t.area_id = a.area_id
                                       AND t.state_code = a.state_code)
                         WHERE     a.state_code = s.state_code
                               AND a.end_date IS NULL
                               AND a.zip IS NOT NULL
                               AND a.zip9 IS NOT NULL
                        GROUP BY a.area_id, t.unique_area, gp.geo_area_key)
                ORDER BY unique_area, geo_area_key;

            COMMIT;
        END LOOP;

        DELETE FROM kpmg_ext_ua_polygon d
         WHERE (unique_area, area_id, geo_area_key) IN
                   (SELECT t1.unique_area, t1.area_id, t1.geo_area_key
                      FROM kpmg_ext_ua_polygon t1,
                           kpmg_ext_ua_polygon t2
                     WHERE     t1.unique_area NOT LIKE
                                   '%' || t2.geo_area_key || '%'
                           AND t1.geo_area_key = t2.geo_area_key
                           AND t1.unique_area = t2.unique_area
                           AND t1.area_id = t2.area_id);

        COMMIT;
    END;

    PROCEDURE load_area_detail_table
    IS
    begin
            execute immediate 'drop table kpmg_ext_area_detail';
            execute immediate '
            CREATE TABLE kpmg_ext_area_detail AS
            SELECT DISTINCT state_code, REGEXP_REPLACE (
                    ASCIISTR (REPLACE (unique_area, ''???'', '''''''')),
                    ''\\[[:xdigit:]]{4}'', '' '')
                    unique_area,area_id,
                    TO_CHAR (poly_startdate, ''mm/dd/yyyy'') start_date,
                    TO_CHAR (poly_enddate, ''mm/dd/yyyy'') end_date
              FROM (SELECT /*+index(m geo_usps_mv_i1) parallel(a, 8) */
                        DISTINCT a.area_id,
                        t.unique_area,
                        MAX (a.start_date) poly_startdate,
                        MAX (a.end_date) poly_enddate,
                        a.state_code
                    FROM geo_usps_lookup a
                    JOIN geo_unique_areas ua ON (ua.area_id = a.area_id)
                    JOIN kpmg_ua_area t ON (    t.area_id = a.area_id AND t.state_code = a.state_code)
                  WHERE a.end_date IS NULL
                    AND a.zip IS NOT NULL
                    AND a.zip9 IS NOT NULL
                GROUP BY a.area_id, t.unique_area, a.state_code)'
            ;
    execute immediate 'CREATE INDEX content_repo.kpmg_ext_area_detail_i1 ON content_repo.kpmg_ext_area_detail ( area_id, state_code)';
    -- execute immediate 'CREATE INDEX content_repo.kpmg_ext_area_detail_i2 ON content_repo.kpmg_ext_area_detail ( state_code, unique_area)';
    execute immediate 'CREATE INDEX content_repo.kpmg_ext_area_detail_i3 ON content_repo.kpmg_ext_area_detail ( state_code)';
    END;


    PROCEDURE load_jurisdictions_table (extract_date VARCHAR2)
    IS
        CURSOR states
        IS
            SELECT DISTINCT SUBSTR (official_name, 1, 2) state_code
              FROM kpmg_rates
             WHERE SUBSTR (official_name, 1, 2) =
                       SUBSTR (official_name, 1, 2);
    BEGIN
        EXECUTE IMMEDIATE 'truncate table kpmg_ext_jurisdictions';

        --execute immediate 'alter index kpmg_ext_jurisdictions_i1 unusable';

        FOR s IN states
        LOOP
            INSERT ALL INTO kpmg_ext_jurisdictions
                /*
                SELECT DISTINCT
                    J1.JURISDICTION_NAME ,
                    J1.DESCRIPTION ,
                    J1.GEO_AREA ,
                    J1.START_DATE,
                    J1.end_date
                FROM MV_KPMG_EXTRACT_JURISDICTIONS J1, Jurisdictions J2
                where j1.jurisdiction_name = j2.official_name -- To make sure we are extracting those records that are already published.
                  and ( j2.status = 2  or j2.entered_by = -2918 )
                  and SUBSTR(jurisdiction_name, 1, 2) = s.state_code
                  and   (j2.status_modified_date <= to_date('06-Jun-2016')
                                        or j2.entered_by = -2918
                                 )
                ORDER BY
                    jurisdiction_name;
                */
                SELECT DISTINCT /*+ parallel(j,4) */
                       REPLACE (official_name, '-  ', '- ') official_name,
                       description,
                       location_category,
                       TO_CHAR (TO_DATE (start_date, 'mm/dd/yyyy'),
                                'mm/dd/yyyy')
                           start_date,
                       TO_CHAR (TO_DATE (end_date, 'mm/dd/yyyy'),
                                'mm/dd/yyyy')
                           end_date
                  FROM vjurisdictions j
                       JOIN
                       (SELECT rid
                          FROM (SELECT rid
                                  FROM (SELECT nkid, MAX (id) rid
                                          FROM jurisdiction_revisions r1
                                         WHERE     status = 2
                                               AND status_modified_date <=
                                                       extract_date
                                               AND nkid IN
                                                       (SELECT DISTINCT
                                                               ref_nkid
                                                          FROM jurisdiction_tags a join tags b on
                                                          ( a.tag_id = b.id)
                                                          where ( b.name = 'United States' or b.name = 'KPMG')
                                                               AND ref_nkid NOT IN
                                                                       (SELECT ref_nkid
                                                                          FROM jurisdiction_tags a join tags t
                                                                            on ( a.tag_id = t.id)
                                                                            where t.name = 'Deprecated'
                                                                                   ))
                                        GROUP BY nkid
                                        /*
                                        UNION
                                        SELECT nkid, MAX (id) rid
                                          FROM jurisdiction_revisions
                                         WHERE     entered_by = -2918
                                               --SAM 12/22/2016 Changed Column from ENTERED_DATE to STATUS_MODIFIED_DATE
                                               -- This is to work around a bug in the jurisdiction_revisions trigger that is updateing the
                                               -- ENTERED_DATE when a new revision is created
                                               AND (TRUNC (status_modified_date) BETWEEN '06-DEC-2016'
                                                                             AND '07-DEC-2016')
                                        GROUP BY nkid
                                        */))) r
                           ON j.juris_entity_rid = r.rid
                 WHERE j.official_name LIKE s.state_code || '%'
                ORDER BY 1;

            COMMIT;
        END LOOP;
    END;

    PROCEDURE load_taxes_table (extract_date VARCHAR2)
    IS
        CURSOR states
        IS
            SELECT DISTINCT SUBSTR (official_name, 1, 2) state_code
              FROM kpmg_rates
             WHERE SUBSTR (official_name, 1, 2) =
                       SUBSTR (official_name, 1, 2);
    BEGIN
        EXECUTE IMMEDIATE 'truncate table kpmg_ext_juris_taxes';

        --execute immediate 'alter index kpmg_ext_juris_taxes_i2 unusable';
        --execute immediate 'alter index kpmg_ext_juris_taxes_i1 unusable';

        FOR s IN states
        LOOP
            -- 08-30-2016
            INSERT ALL INTO kpmg_ext_juris_taxes

            /*  01-19-2017
            SELECT t.juris_tax_id juris_tax_id,
                       REPLACE (j.official_name, '-  ', '- ') official_name,
                       tds.taxation_type,
                       jti.reference_code,
                       tds.transaction_type,
                       tds.specific_applicability_type,
                       rp.name revenue_purpose_description,
                       --td.ref_juris_tax_id,
                       tcs.tax_structure_type,
                       td.value_type value_type,
                       CASE
                           WHEN td.value_type = 'Referenced'
                           THEN
                               (SELECT reference_code
                                  FROM juris_tax_impositions
                                 WHERE     id = td.ref_juris_tax_id
                                       AND next_rid IS NULL)
                           ELSE
                               NULL
                       END
                           referenced_code,
                       CASE
                           WHEN td.value_type = 'Referenced'
                           THEN
                               (SELECT DISTINCT VALUE
                                  FROM tax_definitions td2,
                                       tax_outlines tou2,
                                       juris_tax_impositions jti2
                                 WHERE     jti2.id = td.ref_juris_tax_id
                                       AND tou2.juris_tax_imposition_id =
                                               jti2.id
                                       AND td2.tax_outline_id = tou2.id
                                       AND tou2.next_rid IS NULL
                                       AND jti2.next_rid IS NULL
                                       AND TO_DATE (t.start_date,
                                                    'mm/dd/yyyy') >=
                                               tou2.start_date
                                       AND NVL (
                                               TO_DATE (t.end_date,
                                                        'mm/dd/yyyy'),
                                               SYSDATE) <=
                                               NVL (tou2.end_date, SYSDATE)
                                       AND (   tou2.status = 2
                                            OR tou2.entered_by = -2918)
                                       AND ROWNUM = 1)
                           ELSE
                               td.VALUE
                       END
                           VALUE,
                       td.min_threshold min_threshold,
                       td.max_limit max_limit,
                       t.start_date,
                       t.end_date,
                       --td.definition_status definition_status,
                       t.rid out_rid
                  FROM vtax_outlines t
                       INNER JOIN vtax_definitions2 td
                           ON     td.juris_tax_rid = t.juris_tax_rid
                              AND td.tax_outline_nkid = t.nkid
                       JOIN
                       (SELECT nkid, rid
                          FROM (SELECT nkid, MAX (id) rid
                                  FROM jurisdiction_tax_revisions r1
                                 WHERE     status = 2
                                       AND status_modified_date <=
                                               extract_date
                                       AND entered_by != -2918
                                       AND nkid IN
                                               (SELECT DISTINCT ref_nkid
                                                  FROM juris_tax_imposition_tags a join tags t on ( a.tag_id = t.id)
                                                where ( t.name = 'United States' or t.name = 'KPMG')
                                                       AND ref_nkid NOT IN
                                                               (SELECT ref_nkid
                                                                  FROM juris_tax_imposition_tags c join tags d
                                                                  on c.tag_id = d.id
                                                                  where d.name = 'Deprecated'
                                                                 ))
                                GROUP BY nkid
                                /*
                                UNION
                                SELECT nkid, MAX (id) rid
                                  FROM jurisdiction_tax_revisions
                                 WHERE     entered_by = -2918
                                               --SAM 12/22/2016 Changed Column from ENTERED_DATE to STATUS_MODIFIED_DATE
                                               -- This is to work around a bug in the jurisdiction_revisions trigger that is updateing the
                                               -- ENTERED_DATE when a new revision is created
                                       AND (TRUNC (status_modified_date) BETWEEN '06-DEC-2016'
                                                                     AND '07-DEC-2016')
                                GROUP BY nkid
                                */
                    --            )) r
                          /*
                           ON r.rid = t.juris_tax_rid
                       JOIN juris_tax_impositions jti
                           ON (jti.nkid = r.nkid AND jti.next_rid IS NULL)
                       JOIN jurisdictions j
                           ON (    jti.jurisdiction_nkid = j.nkid
                               AND j.next_rid IS NULL)
                       JOIN
                       (SELECT DISTINCT a1.id,
                                        a2.name transaction_type,
                                        a3.name taxation_type,
                                        a4.name specific_applicability_type
                          FROM tax_descriptions a1
                               JOIN transaction_types a2
                                   ON (a1.transaction_type_id = a2.id)
                               JOIN taxation_types a3
                                   ON (a1.taxation_type_id = a3.id)
                               JOIN specific_applicability_types a4
                                   ON (a1.spec_applicability_type_id = a4.id))
                       tds
                           ON (jti.tax_description_id = tds.id)
                       LEFT JOIN revenue_purposes rp
                           ON (NVL (jti.revenue_purpose_id, -1) = rp.id)
                       JOIN
                       (SELECT a1.id,
                               a2.description tax_structure_type,
                               a3.description amount_type
                          FROM tax_calculation_structures a1
                               JOIN tax_structure_types a2
                                   ON (a2.id = a1.tax_structure_type_id)
                               JOIN amount_types a3
                                   ON (a1.amount_type_id = a3.id)) tcs
                           ON (tcs.id = t.calculation_structure_id)
                 WHERE j.official_name LIKE s.state_code || '%'
                       AND t.Juris_tax_id NOT IN (SELECT ref_nkid from JURIS_TAX_IMPOSITION_TAGS where tag_id IN (72,73))
                ORDER BY j.official_name,
                         t.rid,
                         t.end_date DESC,
                         t.start_date DESC,
                         referenced_code ASC;
                */
                SELECT /*+parallel(t,4) parallel(td,4)*/t.juris_tax_id juris_tax_id,
                       REPLACE (j.official_name, '-  ', '- ') official_name,
                       tds.taxation_type,
                       jti.reference_code,
                       tds.transaction_type,
                       tds.specific_applicability_type,
                       rp.name revenue_purpose_description,
                       --td.ref_juris_tax_id,
                       tcs.tax_structure_type,
                       td.value_type value_type,
                       CASE
                           WHEN td.value_type = 'Referenced'
                           THEN
                               (SELECT reference_code
                                  FROM juris_tax_impositions
                                 WHERE     id = td.ref_juris_tax_id
                                       AND next_rid IS NULL)
                           ELSE
                               NULL
                       END
                           referenced_code,
                       CASE
                           WHEN td.value_type = 'Referenced'
                           THEN
                               (SELECT DISTINCT VALUE
                                  FROM tax_definitions td2,
                                       tax_outlines tou2,
                                       juris_tax_impositions jti2
                                 WHERE     jti2.id = td.ref_juris_tax_id
                                       AND tou2.juris_tax_imposition_id =
                                               jti2.id
                                       AND td2.tax_outline_id = tou2.id
                                       AND tou2.next_rid IS NULL
                                       AND jti2.next_rid IS NULL
                                       AND TO_DATE (t.start_date,
                                                    'mm/dd/yyyy') >=
                                               tou2.start_date
                                       AND NVL (
                                               TO_DATE (t.end_date,
                                                        'mm/dd/yyyy'),
                                               SYSDATE) <=
                                               NVL (tou2.end_date, SYSDATE)
                                       AND (   tou2.status = 2
                                            OR tou2.entered_by = -2918)
                                       AND ROWNUM = 1)
                           ELSE
                               td.VALUE
                       END
                           VALUE,
                       td.min_threshold min_threshold,
                       td.max_limit max_limit,
                       t.start_date,
                       t.end_date,
                       --td.definition_status definition_status,
                       t.rid out_rid
                  FROM vtax_outlines t
                       INNER JOIN vtax_definitions2 td
                           ON     td.juris_tax_rid = t.juris_tax_rid
                              AND td.tax_outline_nkid = t.nkid
                       JOIN
                       (SELECT nkid, rid
                          FROM (SELECT nkid, MAX (id) rid
                                  FROM jurisdiction_tax_revisions r1
                                 WHERE     status = 2
                                       AND status_modified_date <=
                                               extract_date
                                       AND nkid IN
                                               (SELECT DISTINCT ref_nkid
                                                  FROM juris_tax_imposition_tags
                                                 WHERE  tag_id IN (1, 10, 74)
                                                       AND ref_nkid NOT IN
                                                               (SELECT ref_nkid
                                                                  FROM juris_tax_imposition_tags
                                                                 WHERE tag_id IN (75)
                                                                 )
                                                                 )
                                GROUP BY nkid
                                )) r
                           ON r.rid = t.juris_tax_rid
                       JOIN juris_tax_impositions jti
                           ON (jti.nkid = r.nkid AND jti.next_rid IS NULL)
                       JOIN jurisdictions j
                           ON (    jti.jurisdiction_nkid = j.nkid
                               AND j.next_rid IS NULL)
                       JOIN
                       (SELECT DISTINCT a1.id,
                                        a2.name transaction_type,
                                        a3.name taxation_type,
                                        a4.name specific_applicability_type
                          FROM tax_descriptions a1
                               JOIN transaction_types a2
                                   ON (a1.transaction_type_id = a2.id)
                               JOIN taxation_types a3
                                   ON (a1.taxation_type_id = a3.id)
                               JOIN specific_applicability_types a4
                                   ON (a1.spec_applicability_type_id = a4.id))
                       tds
                           ON (jti.tax_description_id = tds.id)
                       LEFT JOIN revenue_purposes rp
                           ON (NVL (jti.revenue_purpose_id, -1) = rp.id)
                       JOIN
                       (SELECT a1.id,
                               a2.description tax_structure_type,
                               a3.description amount_type
                          FROM tax_calculation_structures a1
                               JOIN tax_structure_types a2
                                   ON (a2.id = a1.tax_structure_type_id)
                               JOIN amount_types a3
                                   ON (a1.amount_type_id = a3.id)) tcs
                           ON (tcs.id = t.calculation_structure_id)
                 WHERE j.official_name LIKE s.state_code|| '%'
                ORDER BY j.official_name,
                         t.rid,
                         t.end_date DESC,
                         t.start_date DESC,
                         referenced_code ASC;

            /*
                insert into kpmg_EXT_JURIS_TAXES
                        SELECT  DISTINCT
                                             JURIS_TAX_ID
                                             ,JURISDICTION_NAME
                                             ,TAXATION_TYPE
                                             ,REFERENCE_CODE
                                             ,TRANSACTION_TYPE
                                             ,spec_applicabiliity_type
                                             ,REVENUE_PURPOSE_DESCRIPTION
                                             ,TAX_STRUCTURE
                                             ,value_type tax_value_type
                                             ,REFERENCED_CODE
                                             ,value  tax_value
                                             ,MIN_THRESHOLD
                                             ,MAX_LIMIT
                                             ,START_DATE
                                             ,END_DATE
                                             ,OUT_RID   -- used for sorting only
                                     FROM    MV_KPMG_JURISTAXES_PUBLISHED mv,vtax_ids tax,jurisdiction_tax_revisions jtr
                                     WHERE   substr(jurisdiction_name,1,2) = s.state_code
                                       and   mv.JURIS_TAX_ID = tax.id
                                       and   tax.nkid = jtr.nkid
                                       and   (jtr.status_modified_date <= to_date('07-Jun-2016')
                                                    or jtr.entered_by = -2918
                                             )
                                     ORDER BY jurisdiction_name,
                                             out_rid,
                                             END_DATE DESC,
                                             START_DATE DESC,
                                             REFERENCED_CODE ASC;
                        commit;
            */
            COMMIT;
        END LOOP;

        EXECUTE IMMEDIATE 'truncate table kpmg_ignore_taxes';

        INSERT ALL INTO kpmg_ignore_taxes
            SELECT DISTINCT juris_tax_id
              FROM (SELECT DISTINCT juris_tax_id,
                                    jurisdiction_name,
                                    taxation_type,
                                    reference_code,
                                    transaction_type,
                                    spec_applicabiliity_type,
                                    tax_structure,
                                    tax_value_type,
                                    reference_code,
                                    COUNT (DISTINCT tax_value),
                                    min_threshold,
                                    max_limit,
                                    start_date,
                                    end_date
                      FROM kpmg_ext_juris_taxes
                    GROUP BY juris_tax_id,
                             jurisdiction_name,
                             taxation_type,
                             reference_code,
                             transaction_type,
                             spec_applicabiliity_type,
                             tax_structure,
                             tax_value_type,
                             reference_code,
                             min_threshold,
                             max_limit,
                             start_date,
                             end_date
                    HAVING COUNT (DISTINCT tax_value) > 1);

        INSERT ALL INTO kpmg_ignore_taxes
            SELECT DISTINCT juris_tax_id
              FROM (SELECT COUNT (juris_tax_id),
                           jurisdiction_name,
                           taxation_type,
                           reference_code,
                           start_date,
                           min_threshold,
                           juris_tax_id
                      FROM kpmg_ext_juris_taxes
                    GROUP BY jurisdiction_name,
                             taxation_type,
                             reference_code,
                             start_date,
                             min_threshold,
                             juris_tax_id
                    HAVING COUNT (juris_tax_id) <> 1);

        INSERT ALL INTO kpmg_ignore_taxes
            SELECT DISTINCT juris_tax_id
              FROM (SELECT a.juris_tax_id a_juris_tax_id,
                           b.juris_tax_id,
                           a.start_date a_start_date,
                           a.end_date a_end_date,
                           b.start_date,
                           b.end_date
                      FROM kpmg_ext_juris_taxes a
                           JOIN kpmg_ext_juris_taxes b
                               ON (a.juris_tax_id = b.juris_tax_id)
                     WHERE     a.reference_code = b.reference_code
                           AND a.tax_structure = b.tax_structure
                           AND TO_DATE (a.start_date, 'mm/dd/yyyy') BETWEEN TO_DATE (
                                                                                b.start_date,
                                                                                'mm/dd/yyyy')
                                                                        AND NVL (
                                                                                TO_DATE (
                                                                                    b.end_date,
                                                                                    'mm/dd/yyyy'),
                                                                                '31-Dec-9999')
                           AND TO_DATE (a.end_date, 'mm/dd/yyyy') BETWEEN TO_DATE (
                                                                              b.start_date,
                                                                              'mm/dd/yyyy')
                                                                      AND NVL (
                                                                              TO_DATE (
                                                                                  b.end_date,
                                                                                  'mm/dd/yyyy'),
                                                                              '31-Dec-9999')
                           AND a.start_date != b.start_date);

        DELETE FROM kpmg_ext_juris_taxes
         WHERE juris_tax_id IN (SELECT DISTINCT tax_id
                                  FROM kpmg_ignore_taxes);

        COMMIT;
    END;

    PROCEDURE load_juris_areas_table
    IS
        CURSOR states
        IS
            SELECT DISTINCT SUBSTR (official_name, 1, 2) state_code
              FROM kpmg_rates
             WHERE SUBSTR (official_name, 1, 2) =
                       SUBSTR (official_name, 1, 2);
    BEGIN
        EXECUTE IMMEDIATE 'truncate table kpmg_ext_juris_area';

        --execute immediate 'alter index kpmg_ext_juris_area_i1 unusable';

        INSERT ALL INTO kpmg_ext_juris_area
            --SAM 12/23/2016 Old Version that does not take Jurisdiction overides into account
            /*SELECT DISTINCT
                   j.official_name jurisdiction_name,
                   REGEXP_REPLACE (
                       ASCIISTR (REPLACE (g.geo_area_key, '???', '''')),
                       '\\[[:xdigit:]]{4}',
                       ' ')
                       geo_area_key,
                   TO_CHAR (NVL (g.start_date, j.start_date), 'mm/dd/yyyy')
                       start_date,
                   TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date
              FROM geo_poly_ref_revisions r
                   JOIN juris_geo_areas ja ON (r.nkid = ja.nkid --AND rev_join (ja.rid, r.id, COALESCE(ja.next_rid, 999999999)) = 1
                                                               )
                   JOIN jurisdictions j
                       ON (ja.jurisdiction_id = j.id AND j.next_rid IS NULL)
                   JOIN geo_polygons g ON (ja.geo_polygon_id = g.id)
             WHERE     g.end_date IS NULL
                   AND j.official_name IN (SELECT jurisdiction_name
                                             FROM kpmg_ext_jurisdictions)
            ORDER BY j.official_name;*/

        --SAM 12/23/2016 New Version that takes Jurisdiction overides into account
        /*
        select distinct *
        from (SELECT DISTINCT
                   j.official_name jurisdiction_name,
                   REGEXP_REPLACE (
                       ASCIISTR (REPLACE (g.geo_area_key, '???', '''')),
                       '\\[[:xdigit:]]{4}',
                       ' ')
                       geo_area_key,
                   TO_CHAR (NVL (g.start_date, j.start_date), 'mm/dd/yyyy')
                       start_date,
                   TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date
              FROM geo_poly_ref_revisions r
                   JOIN juris_geo_areas ja ON (r.nkid = ja.nkid --AND rev_join (ja.rid, r.id, COALESCE(ja.next_rid, 999999999)) = 1
                                                               )
                   JOIN jurisdictions j
                       ON (ja.jurisdiction_id = j.id AND j.next_rid IS NULL)
                   JOIN geo_polygons g ON (ja.geo_polygon_id = g.id)
             WHERE     g.end_date IS NULL
                   AND j.official_name IN (SELECT jurisdiction_name
                                             FROM kpmg_ext_jurisdictions)

            union

             SELECT DISTINCT
                   uaa.value jurisdiction_name,
                   REGEXP_REPLACE (
                       ASCIISTR (REPLACE (gpa.geo_area_key, '???', '''')),
                       '\\[[:xdigit:]]{4}',
                       ' ')
                       geo_area_key,
                   NVL (gpa.start_date, TO_CHAR(j.start_date, 'mm/dd/yyyy'))
                       start_date,
                   TO_CHAR (uaa.end_date, 'mm/dd/yyyy') end_date
              FROM VUNIQUE_AREA_ATTRIBUTES_KPMG UAA
                   JOIN  jurisdictions j ON (uaa.VALUE_ID = j.nkid AND j.next_rid IS NULL)
                   join  vgeo_polygon_areas_kpmg gpa on gpa.unique_area_id = uaa.unique_area_id
             WHERE    1=1
               and gpa.end_date IS NULL
               AND j.official_name IN (SELECT jurisdiction_name FROM kpmg_ext_jurisdictions))
         ORDER BY jurisdiction_name;

         */

         -- 12/25/2016 fix for missing rates

         select distinct *
        from (SELECT DISTINCT /*+ parallel(ja,4) parallel(g,4)*/
                   j.official_name jurisdiction_name,
                   REGEXP_REPLACE (
                       ASCIISTR (REPLACE (g.geo_area_key, '???', '''')),
                       '\\[[:xdigit:]]{4}',
                       ' ')
                       geo_area_key,
                   TO_CHAR (NVL (g.start_date, j.start_date), 'mm/dd/yyyy')
                       start_date,
                   TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date
              FROM juris_geo_areas ja
                   JOIN jurisdictions j
                       ON (ja.jurisdiction_id = j.id AND j.next_rid IS NULL)
                   JOIN geo_polygons g ON (ja.geo_polygon_id = g.id)
             WHERE     ( g.end_date IS NULL or g.end_date > sysdate )
                   AND j.official_name IN (SELECT jurisdiction_name
                                             FROM kpmg_ext_jurisdictions)
            union
             SELECT DISTINCT /*+ parallel(uaa,4) */
                   uaa.value jurisdiction_name,
                   REGEXP_REPLACE (
                       ASCIISTR (REPLACE (gpa.geo_area_key, '???', '''')),
                       '\\[[:xdigit:]]{4}',
                       ' ')
                       geo_area_key,
                   NVL (gpa.start_date, TO_CHAR(j.start_date, 'mm/dd/yyyy'))
                       start_date,
                   TO_CHAR (uaa.end_date, 'mm/dd/yyyy') end_date
              FROM VUNIQUE_AREA_ATTRIBUTES_KPMG UAA
                   JOIN  jurisdictions j ON (uaa.VALUE_ID = j.nkid AND j.next_rid IS NULL)
                   join  vgeo_polygon_areas_kpmg gpa on gpa.unique_area_id = uaa.unique_area_id
             WHERE    1=1
               and gpa.end_date IS NULL
               AND j.official_name IN (SELECT jurisdiction_name FROM kpmg_ext_jurisdictions))
         ORDER BY jurisdiction_name;


        COMMIT;
    --execute immediate 'alter index kpmg_ext_juris_area_i1 rebuild';

    END;

    PROCEDURE generate_temp_tables
    IS
    BEGIN
        NULL;
       /*
        EXECUTE IMMEDIATE 'truncate table kpmg_export_areas_file';

        INSERT ALL
          INTO kpmg_export_areas_file
            SELECT a.state_code a_state_code,
                   a.unique_area a_unique_area,
                   a.area_id a_area_id,
                   a.start_date a_start_date,
                   a.end_date a_end_date,
                   b.unique_area b_unique_area,
                   b.area_id b_area_id,
                   b.geo_area_key b_geo_area_key,
                   c.geo_area_key c_geo_area_key,
                   c.geo_area c_geo_area,
                   c.start_date c_start_date,
                   c.end_date c_end_date
              FROM kpmg_ext_area_detail a,
                   kpmg_ext_ua_polygon b,
                   kpmg_ext_geo_areas c,
                   vkpmg_zip5_final d
             WHERE     a.unique_area = b.unique_area
                   AND a.area_id = b.area_id
                   AND b.geo_area_key = c.geo_area_key
                   AND d.state_code = a.state_code
                   AND d.area_id = a.area_id;

        DELETE FROM kpmg_export_areas_file a
         WHERE NOT EXISTS
                   (SELECT 1
                      FROM vkpmg_zip5_final b
                     WHERE     a.a_state_code = b.state_code
                           AND a.a_area_id = b.area_id);

        DELETE FROM kpmg_export_areas_file
         WHERE     a_state_code = 'NJ'
               AND a_area_id IN
                       (SELECT a_area_id
                          FROM (SELECT COUNT (a_unique_area),
                                       a_state_code,
                                       a_area_id
                                  FROM (SELECT DISTINCT
                                               a_state_code,
                                               a_unique_area,
                                               a_area_id
                                          FROM kpmg_export_areas_file a)
                                GROUP BY a_area_id, a_state_code
                                HAVING COUNT (a_unique_area) > 1))
               AND check_kpmg_atleast_3_bounds (a_unique_area) <= 1;


        DELETE FROM kpmg_export_areas_file
         WHERE     a_unique_area =
                       'NC-37-NORTH CAROLINA|NC-101-JOHNSTON|NC-74580-WILSONS MILLS|NC-74580-WILSONS MILLS'
               AND a_state_code = 'NC'
               AND a_area_id = '37-101-74580';

        DELETE FROM kpmg_export_areas_file
         WHERE a_area_id IN (SELECT DISTINCT a_area_id area_id
                               FROM kpmg_export_areas_file a
                              WHERE check_kpmg_atleast_3_bounds (
                                        a_unique_area) > 1
                             MINUS
                             SELECT DISTINCT area_id
                               FROM kpmg_zip5_export);

        DELETE FROM kpmg_export_areas_file
         WHERE check_kpmg_atleast_3_bounds (a_unique_area) <= 1;

        COMMIT;
        */
    END;


    PROCEDURE export_area_detail_file (dir_i IN VARCHAR2, stcode_i IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype     UTL_FILE.file_type;
        l_stcode    VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir       VARCHAR2 (30) := dir_i;

        l_file_ad   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-AREA_DETAIL.csv';
        vdate       DATE;

        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE us_state = 'Y';
    /* SELECT DISTINCT state_code
     FROM   vjuris_geo_areas
     WHERE  (stcode_i IS NULL AND state_code <> 'US')    -- Returns All States
            OR state_code = stcode_i                     -- Specific State
     ORDER BY state_code;
     */

    BEGIN
        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_ad, 'W');
        UTL_FILE.put_line (
            l_ftype,
            'STATE_CODE,UNIQUE_AREA,AREA_ID,START_DATE,END_DATE');

        DECLARE
            vcnt   NUMBER := 0;
        BEGIN
            SELECT COUNT (1)
              INTO vcnt
              FROM kpmg_export_areas_file d
             WHERE (b_unique_area, b_area_id, b_geo_area_key) IN
                       (SELECT t1.b_unique_area,
                               t1.b_area_id,
                               t1.b_geo_area_key
                          FROM kpmg_export_areas_file t1,
                               kpmg_export_areas_file t2
                         WHERE     t1.b_unique_area NOT LIKE
                                       '%' || t2.b_geo_area_key || '%'
                               AND t1.b_geo_area_key = t2.b_geo_area_key
                               AND t1.b_unique_area = t2.b_unique_area
                               AND t1.b_area_id = t2.b_area_id);

            IF vcnt > 0
            THEN
                raise_application_error (
                    -20201,
                    'There are some missing geo_area_key_names under unique_area');
            END IF;
        END;

        FOR r
            IN (SELECT    '"'
                       || state_code
                       || '","'
                       || unique_area
                       || '","'
                       || area_id
                       || '","'
                       || start_date
                       || '","'
                       || end_date
                       || '"'
                           line
                FROM (SELECT DISTINCT a_state_code state_code,
                                      a_unique_area unique_area,
                                      a_area_id area_id,
                                      a_start_date start_date,
                                      a_end_date end_date
                        FROM kpmg_export_areas_file a
                       WHERE check_kpmg_atleast_3_bounds (a_unique_area) > 1
                      ORDER BY 1))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;


        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;

    PROCEDURE export_area_polygon_file (dir_i IN VARCHAR2, stcode_i IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype     UTL_FILE.file_type;
        l_stcode    VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir       VARCHAR2 (30) := dir_i;

        l_file_up   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-AREA_TO_POLYGON.csv';
        vdate       DATE;

        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE us_state = 'Y';
    BEGIN
        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_up, 'W');

        UTL_FILE.put_line (l_ftype, 'UNIQUE_AREA,AREA_ID,GEO_AREA_KEY');

        FOR r
            IN (SELECT    '"'
                       || unique_area
                       || '","'
                       || area_id
                       || '","'
                       || geo_area_key
                       || '"'
                           line
                FROM (SELECT DISTINCT
                             b_unique_area unique_area,
                             b_area_id area_id,
                             b_geo_area_key geo_area_key
                        FROM kpmg_export_areas_file
                      --  WHERE check_atleast_3_boundaries(a_unique_area) > 1
                      ORDER BY b_unique_area, b_geo_area_key))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;

        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;

    PROCEDURE export_geo_area_file (dir_i IN VARCHAR2, stcode_i IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype     UTL_FILE.file_type;
        l_stcode    VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir       VARCHAR2 (30) := dir_i;

        l_file_ga   VARCHAR2 (30) := 'KPMG-' || l_stcode || '-GEO_AREAS.csv';

        vdate       DATE;

        CURSOR states
        IS
            SELECT DISTINCT SUBSTR (official_name, 1, 2) state_code
              FROM kpmg_rates
             WHERE SUBSTR (official_name, 1, 2) =
                       SUBSTR (official_name, 1, 2);
    /* SELECT DISTINCT state_code
     FROM   vjuris_geo_areas
     WHERE  (stcode_i IS NULL AND state_code <> 'US')    -- Returns All States
            OR state_code = stcode_i                     -- Specific State
     ORDER BY state_code;
     */

    BEGIN
        /*
        create table tmp_export_areas_file as
        select a.jurisdiction_name a_jurisdiction_name,
               a.geo_area_key a_geo_area_key,
               a.start_date a_start_date,
               a.end_date  a_end_date,
               b.unique_area b_unique_area,
               b.area_id b_area_id,
               b.geo_area_key b_geo_area_key,
               c.geo_area_key c_geo_area_key,
               c.geo_area c_geo_area,
               c.start_date c_start_date,
               c.end_date c_end_date
         from kpmg_ext_juris_area a, kpmg_ext_ua_polygon b, kpmg_ext_geo_areas c
        where a.geo_area_key = c.geo_area_key
          and b.geo_area_key = c.geo_area_key;
        */

        /*

        create table tmp_export_areas_file as
        select a.state_code a_state_code,
               a.unique_area a_unique_area,
               a.area_id a_area_id,
               a.start_date a_start_date,
               a.end_date a_end_date,
               b.unique_area b_unique_area,
               b.area_id b_area_id,
               b.geo_area_key b_geo_area_key,
               c.geo_area_key c_geo_area_key,
               c.geo_area c_geo_area,
               c.start_date c_start_date,
               c.end_date c_end_date
         from kpmg_ext_area_detail a, kpmg_ext_ua_polygon b, kpmg_ext_geo_areas c
        where a.unique_area = b.unique_area
          and a.area_id = b.area_id
          and b.geo_area_key = c.geo_area_key
          */


        /*
        create table tmp_export_juris_file as
        WITH dist_geo_area
                 AS (SELECT DISTINCT b_geo_area_key
                       FROM tmp_export_areas_file)
        SELECT a.jurisdiction_name a_jurisdiction_name,
               a.geo_area_key a_geo_area_key,
               a.start_date a_start_date,
               a.end_date a_end_date,
               b.jurisdiction_name,
               b.description,
               b.geo_area,
               b.start_date,
               b.end_date,
               c.juris_tax_id c_juris_tax_id,
               c.jurisdiction_name c_jurisdiction_name,
               c.taxation_type c_taxation_type,
               c.reference_code c_reference_code,
               c.transaction_type c_transaction_type,
               c.spec_applicabiliity_type c_spec_applicabiliity_type,
               c.revenue_purpose_description c_revenue_purpose_description,
               c.tax_structure c_tax_structure,
               c.tax_value_type c_tax_value_type,
               c.referenced_code c_referenced_code,
               c.tax_value c_tax_value,
               c.min_threshold c_min_threshold,
               c.max_limit c_max_limit,
               c.start_date c_start_date,
               c.end_date c_end_date,
               c.out_rid c_out_rid
          FROM kpmg_ext_juris_area a,
               kpmg_ext_jurisdictions b,
               kpmg_ext_juris_taxes c,
               dist_geo_area d
         WHERE     a.jurisdiction_name = b.jurisdiction_name
               AND b.jurisdiction_name = c.jurisdiction_name
               AND a.geo_area_key = d.b_geo_area_key
         */

        -- ********************** --
        -- Generate Geo Area File --
        -- ********************** --
        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_ga, 'W');

        UTL_FILE.put_line (l_ftype,
                           'GEO_AREA_KEY,GEO_AREA,START_DATE,END_DATE');



        FOR r
            IN (SELECT    '"'
                       || geo_area_key
                       || '","'
                       || geo_area
                       || '","'
                       || start_date
                       || '","'
                       || end_date
                       || '"'
                           line
                FROM (SELECT DISTINCT c_geo_area_key geo_area_key,
                                      c_geo_area geo_area,
                                      c_start_date start_date,
                                      c_end_date end_date
                        FROM kpmg_export_areas_file
                      -- WHERE check_atleast_3_boundaries(a_unique_area) > 1
                      ORDER BY c_geo_area_key))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;

        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;

    PROCEDURE export_jurisdiction_file (dir_i IN VARCHAR2, stcode_i IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype     UTL_FILE.file_type;
        l_stcode    VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir       VARCHAR2 (30) := dir_i;

        l_file_up   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-AREA_TO_POLYGON.csv';
        l_file_j    VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-JURISDICTIONS.csv';

        vdate       DATE;

        CURSOR states
        IS
            SELECT DISTinct CODE FROM sbxtax.TB_STATES WHERE US_STATE = 'Y';
    /* SELECT DISTINCT state_code
     FROM   vjuris_geo_areas
     WHERE  (stcode_i IS NULL AND state_code <> 'US')    -- Returns All States
            OR state_code = stcode_i                     -- Specific State
     ORDER BY state_code;
     */

    BEGIN
        -- ************************** --
        -- Generate Jurisdiction File --
        -- ************************** --

        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_j, 'W');
        UTL_FILE.put_line (
            l_ftype,
            'JURISDICTION_NAME,DESCRIPTION,GEO_AREA,START_DATE,END_DATE');

        FOR r
            IN (SELECT    '"'
                       || jurisdiction_name
                       || '","'
                       || description
                       || '","'
                       || geo_area
                       || '","'
                       || start_date
                       || '","'
                       || end_date
                       || '"'
                           line
                FROM ( /*SELECT DISTINCT
                              jurisdiction_name jurisdiction_name,
                              description,
                              geo_area,
                              start_date,
                              end_date
                         FROM kpmg_ext_jurisdictions a
                       ORDER BY jurisdiction_name
                       */
                      SELECT DISTINCT jurisdiction_name jurisdiction_name,
                                      description,
                                      geo_area,
                                      start_date,
                                      end_date
                        FROM                           --tmp_export_juris_file
                             (WITH dist_geo_area
                                       AS (SELECT DISTINCT
                                                  b_geo_area_key, a_area_id
                                             FROM kpmg_export_areas_file)
                              SELECT DISTINCT b.jurisdiction_name,
                                              b.description,
                                              b.geo_area,
                                              b.start_date,
                                              b.end_date
                                FROM kpmg_ext_juris_area a,
                                     kpmg_ext_jurisdictions b,
                                     kpmg_ext_juris_taxes c,
                                     dist_geo_area d
                               WHERE     a.jurisdiction_name =
                                             b.jurisdiction_name
                                     AND b.jurisdiction_name =
                                             c.jurisdiction_name
                                     AND a.geo_area_key = d.b_geo_area_key)
                      ORDER BY jurisdiction_name))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;


        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;

    PROCEDURE export_jurisdiction_area_file (dir_i      IN VARCHAR2,
                                             stcode_i   IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype     UTL_FILE.file_type;
        l_stcode    VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir       VARCHAR2 (30) := dir_i;

        l_file_up   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-AREA_TO_POLYGON.csv';
        l_file_j    VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-JURISDICTIONS.csv';

        vdate       DATE;

        CURSOR states
        IS
            SELECT DISTINCT SUBSTR (official_name, 1, 2) state_code
              FROM kpmg_rates
             WHERE SUBSTR (official_name, 1, 2) =
                       SUBSTR (official_name, 1, 2);

        l_file_ja   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-JURIS_AREAS.csv';
    /* SELECT DISTINCT state_code
     FROM   vjuris_geo_areas
     WHERE  (stcode_i IS NULL AND state_code <> 'US')    -- Returns All States
            OR state_code = stcode_i                     -- Specific State
     ORDER BY state_code;
     */

    BEGIN
        -- ******************************* --
        -- Generate Jurisdiction Area File --
        -- ******************************* --

        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_ja, 'W');
        UTL_FILE.put_line (
            l_ftype,
            'JURISDICTION_NAME,GEO_AREA_KEY,START_DATE,END_DATE');


        FOR r
            IN (SELECT    '"'
                       || jurisdiction_name
                       || '","'
                       || geo_area_key
                       || '","'
                       || start_date
                       || '","'
                       || end_date
                       || '"'
                           line
                FROM (SELECT DISTINCT
                             a.a_jurisdiction_name jurisdiction_name,
                             a.a_geo_area_key geo_area_key,
                             a.a_start_date start_date,
                             a.a_end_date end_date
                        FROM (WITH dist_geo_area
                                       AS (SELECT DISTINCT
                                                  b_geo_area_key, a_area_id
                                             FROM kpmg_export_areas_file)
                              SELECT a.jurisdiction_name a_jurisdiction_name,
                                     a.geo_area_key a_geo_area_key,
                                     a.start_date a_start_date,
                                     a.end_date a_end_date
                                FROM kpmg_ext_juris_area a,
                                     kpmg_ext_jurisdictions b,
                                     kpmg_ext_juris_taxes c,
                                     dist_geo_area d
                               WHERE     a.jurisdiction_name =
                                             b.jurisdiction_name
                                     AND b.jurisdiction_name =
                                             c.jurisdiction_name
                                     AND a.geo_area_key = d.b_geo_area_key) a
                      ORDER BY 1))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;

        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;

    PROCEDURE export_jurisdiction_taxes_file (dir_i      IN VARCHAR2,
                                              stcode_i   IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype     UTL_FILE.file_type;
        l_stcode    VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir       VARCHAR2 (30) := dir_i;

        l_file_up   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-AREA_TO_POLYGON.csv';

        vdate       DATE;

        CURSOR states
        IS
            SELECT DISTINCT SUBSTR (official_name, 1, 2) state_code
              FROM kpmg_rates
             WHERE SUBSTR (official_name, 1, 2) =
                       SUBSTR (official_name, 1, 2);

        l_file_jt   VARCHAR2 (30)
                        := 'KPMG-' || l_stcode || '-JURIS_TO_TAXES.csv';
    /* SELECT DISTINCT state_code
     FROM   vjuris_geo_areas
     WHERE  (stcode_i IS NULL AND state_code <> 'US')    -- Returns All States
            OR state_code = stcode_i                     -- Specific State
     ORDER BY state_code;
     */

    BEGIN
        --delete from tmp_export_juris_file where c_juris_tax_id = 954232 and c_out_rid in  ( 1823036, 1823036 );

        --delete from tmp_export_juris_file where c_out_rid in  ( 1823036, 1823158, 1823076, 1823199, 1823117, 1823240 );

        --delete from tmp_export_juris_file where c_out_rid = 1828811 and c_tax_value = 3.69;

        --delete from tmp_export_juris_file where c_out_rid = 1837336 and c_tax_value = 0.7;

        --commit;

        -- *********************************** --
        -- Generate Jurisdiction to Taxes File --
        -- *********************************** --
        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_jt, 'W');
        UTL_FILE.put_line (
            l_ftype,
               'JURIS_TAX_ID,JURISDICTION_NAME,TAXATION_TYPE,REFERENCE_CODE,TRANSACTION_TYPE,SPECIFIC_APPLICABILITY_TYPE,'
            || 'REVENUE_PURPOSE_DESCRIPTION,TAX_STRUCTURE,TAX_VALUE_TYPE,REFERENCED_CODE,TAX_VALUE,'
            || 'MIN_THRESHOLD,MAX_LIMIT,START_DATE,END_DATE');

        FOR r
            IN (SELECT    '"'
                       || juris_tax_id
                       || '","'
                       || jurisdiction_name
                       || '","'
                       || taxation_type
                       || '","'
                       || reference_code
                       || '","'
                       || transaction_type
                       || '","'
                       || spec_applicabiliity_type
                       || '","'
                       || revenue_purpose_description
                       || '","'
                       || tax_structure
                       || '","'
                       || tax_value_type
                       || '","'
                       || referenced_code
                       || '","'
                       || tax_value
                       || '","'
                       || min_threshold
                       || '","'
                       || max_limit
                       || '","'
                       || start_date
                       || '","'
                       || end_date
                       || '"'
                           line
                FROM (SELECT DISTINCT
                             c_juris_tax_id juris_tax_id,
                             c_jurisdiction_name jurisdiction_name,
                             c_taxation_type taxation_type,
                             c_reference_code reference_code,
                             c_transaction_type transaction_type,
                             c_spec_applicabiliity_type
                                 spec_applicabiliity_type,
                             c_revenue_purpose_description
                                 revenue_purpose_description,
                             c_tax_structure tax_structure,
                             c_tax_value_type tax_value_type,
                             c_referenced_code referenced_code,
                             c_tax_value tax_value,
                             c_min_threshold min_threshold,
                             c_max_limit max_limit,
                             c_start_date start_date,
                             c_end_date end_date,
                             c_out_rid out_rid
                        FROM (WITH dist_geo_area
                                       AS (SELECT DISTINCT
                                                  b_geo_area_key, a_area_id
                                             FROM kpmg_export_areas_file)
                              SELECT DISTINCT
                                     c.juris_tax_id c_juris_tax_id,
                                     c.jurisdiction_name c_jurisdiction_name,
                                     c.taxation_type c_taxation_type,
                                     c.reference_code c_reference_code,
                                     c.transaction_type c_transaction_type,
                                     c.spec_applicabiliity_type
                                         c_spec_applicabiliity_type,
                                     c.revenue_purpose_description
                                         c_revenue_purpose_description,
                                     c.tax_structure c_tax_structure,
                                     c.tax_value_type c_tax_value_type,
                                     c.referenced_code c_referenced_code,
                                     c.tax_value c_tax_value,
                                     c.min_threshold c_min_threshold,
                                     c.max_limit c_max_limit,
                                     c.start_date c_start_date,
                                     c.end_date c_end_date,
                                     c.out_rid c_out_rid
                                FROM kpmg_ext_juris_taxes c
                               WHERE c.jurisdiction_name IN
                                         (SELECT DISTINCT
                                                 jurisdiction_name
                                                     jurisdiction_name
                                            FROM (WITH dist_geo_area
                                                           AS (SELECT DISTINCT
                                                                      b_geo_area_key,
                                                                      a_area_id
                                                                 FROM kpmg_export_areas_file)
                                                  SELECT DISTINCT
                                                         b.jurisdiction_name,
                                                         b.description,
                                                         b.geo_area,
                                                         b.start_date,
                                                         b.end_date
                                                    FROM kpmg_ext_juris_area a,
                                                         kpmg_ext_jurisdictions b,
                                                         kpmg_ext_juris_taxes c,
                                                         dist_geo_area d
                                                   WHERE     a.jurisdiction_name =
                                                                 b.jurisdiction_name
                                                         AND b.jurisdiction_name =
                                                                 c.jurisdiction_name
                                                         AND a.geo_area_key =
                                                                 d.b_geo_area_key)))
                             a
                      ORDER BY c_jurisdiction_name,
                               c_out_rid,
                               c_end_date DESC,
                               c_start_date DESC,
                               c_referenced_code ASC))
        LOOP
            /*
            FOR r IN
            (
                SELECT
                    '"' || JURIS_TAX_ID || '","' || JURISDICTION_NAME || '","' || TAXATION_TYPE || '","' ||
                    REFERENCE_CODE || '","' || TRANSACTION_TYPE || '","' || spec_applicabiliity_type || '","'
                    || REVENUE_PURPOSE_DESCRIPTION || '","' || TAX_STRUCTURE || '","' || TAX_VALUE_TYPE ||
                    '","' || REFERENCED_CODE || '","' || TAX_VALUE || '","' || MIN_THRESHOLD || '","' ||
                    MAX_LIMIT || '","' || START_DATE || '","' || END_DATE || '"' line
                FROM
                    (
                        SELECT distinct
                               c_juris_tax_id juris_tax_id,
                               c_jurisdiction_name JURISDICTION_NAME, c_taxation_type taxation_type,
                               c_reference_code reference_code,
                               c_transaction_type transaction_type, c_spec_applicabiliity_type spec_applicabiliity_type,
                               c_revenue_purpose_description revenue_purpose_description, c_tax_structure tax_structure,
                               c_tax_value_type tax_value_type, c_referenced_code referenced_code, c_tax_value tax_value,
                               c_min_threshold min_threshold, c_max_limit max_limit, c_start_date start_date, c_end_date end_date,
                               c_out_rid out_rid
                                  FROM (WITH dist_geo_area
                                             AS (SELECT DISTINCT b_geo_area_key, a_area_id
                                                   FROM tmp_export_areas_file)
                                    SELECT distinct c.juris_tax_id c_juris_tax_id,
                                           c.jurisdiction_name c_jurisdiction_name,
                                           c.taxation_type c_taxation_type,
                                           c.reference_code c_reference_code,
                                           c.transaction_type c_transaction_type,
                                           c.spec_applicabiliity_type c_spec_applicabiliity_type,
                                           c.revenue_purpose_description c_revenue_purpose_description,
                                           c.tax_structure c_tax_structure,
                                           c.tax_value_type c_tax_value_type,
                                           c.referenced_code c_referenced_code,
                                           c.tax_value c_tax_value,
                                           c.min_threshold c_min_threshold,
                                           c.max_limit c_max_limit,
                                           c.start_date c_start_date,
                                           c.end_date c_end_date,
                                           c.out_rid c_out_rid
                                      FROM kpmg_ext_juris_area a,
                                           kpmg_ext_jurisdictions b,
                                           kpmg_ext_juris_taxes c--,
                                            dist_geo_area d
                                     WHERE     a.jurisdiction_name = b.jurisdiction_name
                                           AND b.jurisdiction_name = c.jurisdiction_name
                                           AND a.geo_area_key = d.b_geo_area_key
                                           ) a
                        ORDER BY
                            c_jurisdiction_name,
                            c_out_rid,
                            c_END_DATE DESC,
                            c_START_DATE DESC,
                            c_REFERENCED_CODE ASC ) )
            LOOP
            */
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;


        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;

    PROCEDURE generate_zip4_file(dir_i IN VARCHAR2)
    AS
    BEGIN
        FOR l IN (SELECT DISTINCT code state_code
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y'
                  ORDER BY 1)
        LOOP
            DECLARE
                l_file_z4   VARCHAR2 (2000);
                l_ftype     UTL_FILE.file_type;
                l_stcode    VARCHAR2 (3) := l.state_code;
                l_dir       VARCHAR2 (30) := dir_i;
                line_zip4   VARCHAR2 (4300);
                line_zip5   VARCHAR2 (4300);
                vdate       DATE;
                vcnt        NUMBER := 0;
            BEGIN
                l_file_z4 := 'KPMG-' || l.state_code || '-ZIP4.csv';
                l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_z4, 'W');

                UTL_FILE.put_line (l_ftype, 'AREA_ID,ZIP,ZIP4');

                FOR r
                    IN (SELECT DISTINCT a.*
                        FROM kpmg_zip4_export a
                             JOIN kpmg_zip5_export b
                                 ON (    a.state_code = b.state_code
                                     AND a.area_id = b.area_id
                                     AND a.zip = b.zip)
                        WHERE     a.state_code = l.state_code
                              AND a.default_flag = 'Y'
                        ORDER BY a.zip, a.plus4_range, a.area_id)
                LOOP
                    line_zip4 :=
                           '"'
                        || r.area_id
                        || '","'
                        || r.zip
                        || '","'
                        || r.plus4_range
                        || '"';

                    UTL_FILE.put_line (l_ftype, line_zip4);
                END LOOP;

                UTL_FILE.fflush (l_ftype);
                UTL_FILE.fclose (l_ftype);
            END;
        END LOOP;
    END;

    PROCEDURE generate_zip5_file(dir_i IN VARCHAR2)
    IS
        l_file_z5   VARCHAR2 (2000);
        l_ftype     UTL_FILE.file_type;
        l_dir       VARCHAR2 (30) := dir_i;
        line_zip4   VARCHAR2 (4300);
        line_zip5   VARCHAR2 (4300);
        vdate       DATE;
        vcnt        NUMBER := 0;
    BEGIN
        l_file_z5 := 'KPMG-' || 'ALL' || '-ZIP5.csv';
        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_z5, 'W');

        UTL_FILE.put_line (l_ftype, 'AREA_ID,ZIP,ZIP4');

        FOR l IN (SELECT DISTINCT code state_code
                  FROM sbxtax.tb_states
                  WHERE us_state = 'Y'
                  ORDER BY 1)
        LOOP
            FOR r
                IN (SELECT DISTINCT b.*
                    FROM kpmg_zip4_export a
                         JOIN kpmg_zip5_export b
                             ON (    a.state_code = b.state_code
                                 AND a.area_id = b.area_id
                                 AND a.zip = b.zip)
                    WHERE     a.state_code = l.state_code
                          AND a.default_flag = 'Y'
                    ORDER BY b.area_id, b.zip)
            LOOP
                line_zip5 :=
                       '"'
                    || r.area_id
                    || '","'
                    || r.zip
                    || '","'
                    || r.default_flag
                    || '"';

                UTL_FILE.put_line (l_ftype, line_zip5);
            END LOOP;
        END LOOP;

        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;


    PROCEDURE export_applicabilities_file (dir_i      IN VARCHAR2,
                                           stcode_i   IN CHAR)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype           UTL_FILE.file_type;
        l_stcode          VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir             VARCHAR2 (30) := dir_i;

        l_file_ga         VARCHAR2 (30) := 'KPMG-' || l_stcode || '-GEO_AREAS.csv';
        l_file_ad         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-AREA_DETAIL.csv';
        l_file_up         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-AREA_TO_POLYGON.csv';


        l_file_j          VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-JURISDICTIONS.csv';
        l_file_jt         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-JURIS_TO_TAXES.csv';
        l_file_ja         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-JURIS_AREAS.csv';


        l_file_z4         VARCHAR2 (30) := 'KPMG-' || l_stcode || '-ZIP4.csv';
        l_file_z5         VARCHAR2 (30) := 'KPMG-' || l_stcode || '-ZIP5.csv';

        -------------------------------------
        -- File names for Applicabilities
        --------------------------------------
        l_file_appl       VARCHAR2 (50) := 'KPMG-APPLICABILITIES.csv';
        l_file_tax_appl   VARCHAR2 (50)
            := 'KPMG-' || l_stcode || '-TAX_APPLICABILITY.csv';
        -- l_file_tax_appl_notes VARCHAR2(60) := 'KPMG-' || l_stcode || '-Tax-Applicabiliity-Notes.csv';


        line_zip4         VARCHAR2 (4300);
        line_zip5         VARCHAR2 (4300);
        vdate             DATE;
        vcnt              NUMBER := 0;

        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE us_state = 'Y';
    BEGIN
        -- Commodities file

        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_appl, 'W');
        UTL_FILE.put_line (
            l_ftype,
            'COMMODITY_ID,COMMODITY_NAME,COMMODITY_DESCRIPTION');

        INSERT INTO kpmg_log
        VALUES ('About to process Commodities ', SYSDATE);

        COMMIT;

        EXECUTE IMMEDIATE 'truncate table kpmg_ext_appl';

        INSERT ALL INTO kpmg_ext_appl
            SELECT DISTINCT
                   c.id commodity_id,
                   REPLACE (REPLACE (REPLACE (c.name, '"', ''''), '`', ''''),
                            '”',
                            '''')
                       commodity_name,
                   REPLACE (
                       REPLACE (REPLACE (c.description, '"', ''''),
                                '”',
                                ''''),
                       '`',
                       '''')
                       commodity_description
              FROM commodities c, commodity_revisions cr
             WHERE     c.rid = cr.id
                   AND c.product_tree_id IN (SELECT id
                                               FROM product_trees
                                              WHERE name IN ('US', 'KPMG'))
                   AND (c.status = 2 OR c.entered_by = -2918)
            ORDER BY c.id;


        FOR r
            IN (SELECT    '"'
                       || commodity_id
                       || '","'
                       || commodity_name
                       || '","'
                       || commodity_description
                       || '"'
                           line
                FROM (SELECT DISTINCT
                             commodity_id,
                             c.commodity_name commodity_name,
                             SUBSTR (c.commodity_description, 255)
                                 commodity_description
                        FROM kpmg_ext_appl c))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;

        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
    END;


    PROCEDURE export_tax_applicabilities (dir_i      IN VARCHAR2,
                                          stcode_i   IN CHAR,
                                          flag          NUMBER DEFAULT 0)
    IS
        -- Create a separate CSV for each of the 8 files to be sent to KPMG --

        l_ftype           UTL_FILE.file_type;
        l_stcode          VARCHAR2 (3)
            := CASE WHEN stcode_i IS NULL THEN 'ALL' ELSE stcode_i END;
        l_dir             VARCHAR2 (30) := dir_i;

        l_file_ga         VARCHAR2 (30) := 'KPMG-' || l_stcode || '-GEO_AREAS.csv';
        l_file_ad         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-AREA_DETAIL.csv';
        l_file_up         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-AREA_TO_POLYGON.csv';


        l_file_j          VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-JURISDICTIONS.csv';
        l_file_jt         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-JURIS_TO_TAXES.csv';
        l_file_ja         VARCHAR2 (30)
                              := 'KPMG-' || l_stcode || '-JURIS_AREAS.csv';


        l_file_z4         VARCHAR2 (30) := 'KPMG-' || l_stcode || '-ZIP4.csv';
        l_file_z5         VARCHAR2 (30) := 'KPMG-' || l_stcode || '-ZIP5.csv';

        -------------------------------------
        -- File names for Applicabilities
        --------------------------------------
        l_file_appl       VARCHAR2 (50) := 'KPMG-APPLICABILITIES.csv';
        l_file_tax_appl   VARCHAR2 (50)
            := 'KPMG-' || l_stcode || '-TAX_APPLICABILITY.csv';
        -- l_file_tax_appl_notes VARCHAR2(60) := 'KPMG-' || l_stcode || '-Tax-Applicabiliity-Notes.csv';


        line_zip4         VARCHAR2 (4300);
        line_zip5         VARCHAR2 (4300);
        vdate             DATE;
        vcnt              NUMBER := 0;

        CURSOR states
        IS
            SELECT DISTINCT code state_code
              FROM sbxtax.tb_states
             WHERE us_state = 'Y';
    /* SELECT DISTINCT state_code
     FROM   vjuris_geo_areas
     WHERE  (stcode_i IS NULL AND state_code <> 'US')    -- Returns All States
            OR state_code = stcode_i                     -- Specific State
     ORDER BY state_code;
     */

    BEGIN
        -- Commodities file



        IF flag = 1
        THEN
            EXECUTE IMMEDIATE 'truncate table kpmg_ext_tax_appl';

            FOR s IN states
            LOOP
                INSERT ALL INTO kpmg_ext_tax_appl
                    SELECT jti.id juris_tax_id,
                           jta.commodity_id,
                           TO_CHAR (jti.start_date, 'mm/dd/yyyy') start_date,
                           TO_CHAR (jti.end_date, 'mm/dd/yyyy') end_date
                      FROM juris_tax_applicabilities jta
                           JOIN tax_applicability_taxes tat
                               ON (jta.nkid =
                                       tat.juris_tax_applicability_nkid)
                           JOIN juris_tax_impositions jti
                               ON (jti.nkid = tat.juris_tax_imposition_nkid)
                           JOIN kpmg_ext_juris_taxes kt
                               ON (kt.juris_tax_id = jti.id)
                           JOIN kpmg_ext_jurisdictions j
                               ON (j.jurisdiction_name = kt.jurisdiction_name)
                           JOIN jurisdictions j
                               ON (    j.official_name = kt.jurisdiction_name
                                   AND jta.jurisdiction_nkid = j.nkid)
                     WHERE     jta.commodity_id IS NOT NULL
                           AND SUBSTR (j.official_name, 1, 2) = s.state_code
                           AND jta.status = 2
                           AND EXISTS
                                   (SELECT 1
                                      FROM juris_tax_app_tags b
                                     WHERE     b.ref_nkid = jta.nkid
                                           AND tag_id IN (1, 10))
                           AND NOT EXISTS
                                   (SELECT 1
                                      FROM juris_tax_app_tags c
                                     WHERE     c.ref_nkid = jta.nkid
                                           AND tag_id IN (72,73))
                    UNION
                    SELECT *
                      FROM (WITH dist_geo_area
                                     AS (SELECT DISTINCT
                                                b_geo_area_key, a_area_id
                                           FROM kpmg_export_areas_file)
                            SELECT jti.id juris_tax_id,
                                   c.id commodity_id,
                                   TO_CHAR (jti.start_date, 'mm/dd/yyyy'),
                                   TO_CHAR (jti.end_date, 'mm/dd/yyyy')
                              FROM kpmg_comm_taxes t
                                   JOIN juris_tax_impositions jti
                                       ON (t.taxid = jti.id)
                                   JOIN kpmg_rateappl rl
                                       ON (rl.ratekeyid = t.ratekeyid)
                                   JOIN kpmg_appl_types al
                                       ON (al.masterservicetypeid =
                                               rl.masterservicetypeid)
                                   JOIN commodities c
                                       ON (al.servicetypecode || al.subservicetypecode =
                                               c.commodity_code)
                                   JOIN kpmg_ext_juris_taxes kt
                                       ON (kt.juris_tax_id = jti.id)
                                   JOIN kpmg_ext_jurisdictions j
                                       ON (j.jurisdiction_name =
                                               kt.jurisdiction_name)
                                   JOIN kpmg_ext_juris_area t
                                       ON (t.jurisdiction_name =
                                               kt.jurisdiction_name)
                                   JOIN dist_geo_area tx
                                       ON (tx.b_geo_area_key = t.geo_area_key)
                                   JOIN jurisdictions j
                                       ON (j.official_name =
                                               kt.jurisdiction_name)
                             WHERE SUBSTR (j.official_name, 1, 2) =
                                       s.state_code)
                      UNION
                        select juris_tax_id, commodity_id, to_char(start_date, 'mm/dd/yyyy'), to_char(start_date, 'mm/dd/yyyy')
                          from kpmg_load_appl_manual
                    ORDER BY 1;

                COMMIT;
            END LOOP;
        END IF;

        l_ftype := UTL_FILE.fopen (UPPER (l_dir), l_file_tax_appl, 'W');
        UTL_FILE.put_line (l_ftype,
                           'JURIS_TAX_ID,COMMODITY_ID,START_DATE,END_DATE');

        /*
        create table kpmg_taxes as
        WITH dist_geo_area
        AS (SELECT DISTINCT b_geo_area_key, a_area_id
        FROM tmp_export_areas_file)
        SELECT distinct c.juris_tax_id c_juris_tax_id
                                  FROM kpmg_ext_juris_area a,
                                       kpmg_ext_jurisdictions b,
                                       kpmg_ext_juris_taxes c,
                                       dist_geo_area d
                                 WHERE     a.jurisdiction_name = b.jurisdiction_name
                                       AND b.jurisdiction_name = c.jurisdiction_name
                                       AND a.geo_area_key = d.b_geo_area_key
        */

        /*
        drop table kpmg_taxes;

        create table kpmg_taxes as
        SELECT DISTINCT c_juris_tax_id juris_tax_id
          FROM (WITH dist_geo_area
                         AS (SELECT DISTINCT b_geo_area_key, a_area_id
                               FROM tmp_export_areas_file)
                SELECT DISTINCT
                       c.juris_tax_id c_juris_tax_id,
                       c.jurisdiction_name c_jurisdiction_name,
                       c.taxation_type c_taxation_type,
                       c.reference_code c_reference_code,
                       c.transaction_type c_transaction_type,
                       c.spec_applicabiliity_type c_spec_applicabiliity_type,
                       c.revenue_purpose_description c_revenue_purpose_description,
                       c.tax_structure c_tax_structure,
                       c.tax_value_type c_tax_value_type,
                       c.referenced_code c_referenced_code,
                       c.tax_value c_tax_value,
                       c.min_threshold c_min_threshold,
                       c.max_limit c_max_limit,
                       c.start_date c_start_date,
                       c.end_date c_end_date,
                       c.out_rid c_out_rid
                  FROM kpmg_ext_juris_taxes c
                 WHERE c.jurisdiction_name IN
                           (SELECT DISTINCT jurisdiction_name jurisdiction_name
                              FROM (WITH dist_geo_area
                                             AS (SELECT DISTINCT
                                                        b_geo_area_key, a_area_id
                                                   FROM tmp_export_areas_file)
                                    SELECT DISTINCT b.jurisdiction_name,
                                                    b.description,
                                                    b.geo_area,
                                                    b.start_date,
                                                    b.end_date
                                      FROM kpmg_ext_juris_area a,
                                           kpmg_ext_jurisdictions b,
                                           kpmg_ext_juris_taxes c,
                                           dist_geo_area d
                                     WHERE     a.jurisdiction_name =
                                                   b.jurisdiction_name
                                           AND b.jurisdiction_name =
                                                   c.jurisdiction_name
                                           AND a.geo_area_key = d.b_geo_area_key))) a
        */
        FOR r
            IN (SELECT    '"'
                       || tax_imposition_id
                       || '","'
                       || commodity_id
                       || '","'
                       || start_date
                       || '","'
                       || end_date
                       || '"'
                           line
                FROM ( /*
                         select distinct tax_imposition_id, commodity_id, start_date, end_date
                           from kpmg_Ext_Tax_Appl a
                          where commodity_id in (select commodity_id from kpmg_ext_appl)
                            and exists ( select 1 FROM kpmg_taxes tt where tt.juris_tax_id = a.tax_imposition_id
                                         )
                            and not exists ( select 1 from kpmg_ignore_taxes d where d.tax_id = a.tax_imposition_id )
                          order by tax_imposition_id
                      */
                      SELECT DISTINCT a.tax_imposition_id,
                                      a.commodity_id,
                                      a.start_date,
                                      a.end_date
                        FROM kpmg_ext_tax_appl a
                             JOIN kpmg_taxes t
                                 ON (t.juris_tax_id = a.tax_imposition_id)
                             JOIN kpmg_ext_appl t1
                                 ON (t1.commodity_id = a.commodity_id)
                       WHERE NOT EXISTS
                                 (SELECT 1
                                    FROM kpmg_ignore_taxes d
                                   WHERE d.tax_id = a.tax_imposition_id)
                      UNION
                      SELECT DISTINCT a.juris_tax_id,
                                      a.commodity_id,
                                      to_char(a.start_date, 'mm/dd/yyyy') start_date,
                                      to_char(a.end_date, 'mm/dd/yyyy') end_date
                        FROM kpmg_load_appl_manual a
                             JOIN kpmg_taxes t
                                 ON (t.juris_tax_id = a.juris_tax_id)
                             JOIN kpmg_ext_appl t1
                                 ON (t1.commodity_id = a.commodity_id)
                       WHERE NOT EXISTS
                                 (SELECT 1
                                    FROM kpmg_ignore_taxes d
                                   WHERE d.tax_id = a.juris_tax_id)
                      ORDER BY tax_imposition_id))
        LOOP
            UTL_FILE.put_line (l_ftype, r.line);
        END LOOP;
        UTL_FILE.fflush (l_ftype);
        UTL_FILE.fclose (l_ftype);
        commit;
    END;


    PROCEDURE generate_all_files (regenrate_flag NUMBER, dir_i VARCHAR2)
    IS
    BEGIN
        IF NVL (regenrate_flag, -999) = 1 -- This indicates this data has been captured for previous data set.
        -- We can use the same data set infor for zip files , if so then pass extract-set_i = 2
        -- else 1, which will generate the full file data set from begining.
        THEN
            --SAM 12/22/2016 Added to refresh the table as it was stale
            --generate_ua_area;
            DBMS_OUTPUT.put_line ('generate_ua_area Compelted');

            --generate_zip_pt;
            DBMS_OUTPUT.put_line ('generate_zip_pt Compelted');

            -- generate_zip_pt3;
            DBMS_OUTPUT.put_line ('generate_zip_pt3 completed');
        /*
            generate_zip_final;
            DBMS_OUTPUT.put_line ('generate_zip_final completed');
        */

            --remove_bad_data;
            DBMS_OUTPUT.put_line ('remove_bad_data completed');

            generate_final_zip_tables;
            DBMS_OUTPUT.put_line ('generate_final_zip_tables completed');

            replace_zip4_alpha;
            DBMS_OUTPUT.put_line ('replace_zip4_alpha completed');

            generate_temp_tables; -- 12/09/16, moved this call from LOAD_DATA because it requires data from above procedures
            DBMS_OUTPUT.put_line ('generate_temp_tables completed');
        END IF;


        kpmg_purge_data_checks;
        dbms_output.put_line('Data Check failure data cleared');

        perform_datachecks;
        DBMS_OUTPUT.put_line ('perform_datachecks completed');

        export_area_detail_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_area_detail_file completed');

        export_area_polygon_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_area_polygon_file completed');

        export_geo_area_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_geo_area_file completed');

        export_jurisdiction_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_jurisdiction_file completed');

        export_jurisdiction_area_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_jurisdiction_area_file completed');

        export_jurisdiction_taxes_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_jurisdiction_taxes_file completed');

        generate_zip4_file(dir_i);  -- 12/08/16 - added dir_i parameter
        DBMS_OUTPUT.put_line ('generate_zip4_file completed');

        generate_zip5_file(dir_i);  -- 12/08/16 - added dir_i parameter
        DBMS_OUTPUT.put_line ('generate_zip5_file completed');

        export_applicabilities_file (dir_i, 'ALL');
        DBMS_OUTPUT.put_line ('export_applicabilities_file completed');

        EXECUTE IMMEDIATE 'drop table kpmg_taxes';

        EXECUTE IMMEDIATE
            'create table kpmg_taxes as
SELECT DISTINCT c_juris_tax_id juris_tax_id
  FROM (WITH dist_geo_area
                 AS (SELECT DISTINCT b_geo_area_key, a_area_id
                       FROM kpmg_export_areas_file)
        SELECT DISTINCT
               c.juris_tax_id c_juris_tax_id,
               c.jurisdiction_name c_jurisdiction_name,
               c.taxation_type c_taxation_type,
               c.reference_code c_reference_code,
               c.transaction_type c_transaction_type,
               c.spec_applicabiliity_type c_spec_applicabiliity_type,
               c.revenue_purpose_description c_revenue_purpose_description,
               c.tax_structure c_tax_structure,
               c.tax_value_type c_tax_value_type,
               c.referenced_code c_referenced_code,
               c.tax_value c_tax_value,
               c.min_threshold c_min_threshold,
               c.max_limit c_max_limit,
               c.start_date c_start_date,
               c.end_date c_end_date,
               c.out_rid c_out_rid
          FROM kpmg_ext_juris_taxes c
         WHERE c.jurisdiction_name IN
                   (SELECT DISTINCT jurisdiction_name jurisdiction_name
                      FROM (WITH dist_geo_area
                                     AS (SELECT DISTINCT
                                                b_geo_area_key, a_area_id
                                           FROM kpmg_export_areas_file)
                            SELECT DISTINCT b.jurisdiction_name,
                                            b.description,
                                            b.geo_area,
                                            b.start_date,
                                            b.end_date
                              FROM kpmg_ext_juris_area a,
                                   kpmg_ext_jurisdictions b,
                                   kpmg_ext_juris_taxes c,
                                   dist_geo_area d
                             WHERE     a.jurisdiction_name =
                                           b.jurisdiction_name
                                   AND b.jurisdiction_name =
                                           c.jurisdiction_name
                                   AND a.geo_area_key = d.b_geo_area_key))) a';

        export_tax_applicabilities (dir_i, 'ALL', 1);
        DBMS_OUTPUT.put_line ('export_tax_applicabilities completed');
    END;

    PROCEDURE load_data (extract_date_i DATE)
    IS
    BEGIN
        -- Takes about 8 minutes to load all the needed data
        load_ua_area;
        load_area_detail_table;
        load_area_polygon_table;
        load_geo_areas_table;
        load_jurisdictions_table (extract_date_i); -- Hard Coded import dates on this, SHould be changed as per prod
        load_taxes_table (extract_date_i); -- Hard Coded import dates on this, SHould be changed as per prod
        load_juris_areas_table;
        --generate_temp_tables; -- 12/09/16, moved this call to within GENERATE_ALL_FILES
    END;

    PROCEDURE load_generate_all_files (extract_date_i    DATE,
                                       dir_i             VARCHAR2,
                                       regenarate        NUMBER)
    IS
    BEGIN
        load_data (extract_date_i);
        generate_all_files (regenarate, dir_i); -- Pass regenerate as 0 to generate all file data from the beginning
        dbms_output.put_line('Process completed successfully');
    -- For all other values, it will not perform the data load again for zip files.
    -- This procedure will also performs data checks if needed, and raises error if there is any issue with check.
    END;
END;
/