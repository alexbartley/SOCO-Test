CREATE OR REPLACE PROCEDURE content_repo."KPMG_PURGE_DATA_CHECKS"
IS
BEGIN

    FOR i IN (SELECT code
              FROM sbxtax.tb_states
              WHERE us_state = 'Y')
    LOOP

        --  datacheck_dup_ua
        DELETE FROM kpmg_export_areas_file
         WHERE (a_state_code, a_area_id) IN
                   (SELECT a_state_code, a_area_id
                      FROM (SELECT DISTINCT
                                   /*+ parallel (a, 8) */ a_state_code, a_unique_area, a_area_id
                              FROM kpmg_export_areas_file a where a_state_code = i.code)
                    GROUP BY a_area_id, a_state_code
                    HAVING COUNT (a_unique_area) > 1);

                --  datacheck_unique_area_zip5

        DELETE FROM kpmg_export_areas_file
         WHERE a_state_code = i.code and a_area_id IN (SELECT DISTINCT area_id
                               FROM ( (SELECT DISTINCT /*+ parallel (a, 8) */a_area_id area_id
                                         FROM kpmg_export_areas_file a
                                        WHERE a_state_code = i.code and
                                         check_kpmg_atleast_3_bounds(
                                                  a_unique_area) > 1
                                       MINUS
                                       SELECT DISTINCT /*+ parallel (b, 8) */area_id
                                         FROM kpmg_zip5_export b where state_code = i.code)
                                    ));


         DELETE FROM kpmg_zip5_export
         WHERE state_code = i.code and area_id IN (SELECT DISTINCT area_id
                               FROM (
                                     (SELECT DISTINCT /*+ parallel (a, 8) */area_id
                                        FROM kpmg_zip5_export a where state_code = i.code
                                      MINUS
                                      SELECT DISTINCT /*+ parallel (a, 8) */a_area_id area_id
                                        FROM kpmg_export_areas_file a
                                       WHERE a_state_code = i.code and check_kpmg_atleast_3_bounds (
                                                 a_unique_area) > 1)));


        DELETE FROM kpmg_zip4_export
         WHERE state_code = i.code AND ASCII (plus4_range) BETWEEN 65 AND 90;

            --  DATACHECK_ZIP5_DUPLDEFAULT
        DELETE FROM kpmg_zip5_export
         WHERE  state_code = i.code and default_flag = 'Y'
               AND (zip, area_id, state_code) IN
                       (SELECT /*+ parallel (a, 8) */zip, area_id, state_code
                          FROM kpmg_zip5_export a
                         WHERE default_flag = 'Y' AND state_code = i.code
                        GROUP BY zip, area_id, state_code
                        HAVING COUNT (default_flag) > 1);

                 --  DATACHECK_ZIP5_NODEFAULT
        DELETE FROM kpmg_zip5_export a
         WHERE     state_code = i.code
               AND default_flag = 'N'
               AND NOT EXISTS
                       (SELECT 1
                          FROM kpmg_zip5_export b
                         WHERE     a.state_code = b.state_code
                               AND a.zip = b.zip
                               AND b.default_flag = 'Y');

        -- DATACHECK_ZIP5_DUPNONDEF

        DELETE FROM kpmg_zip5_export
         WHERE  state_code = i.code and  default_flag = 'N'
               AND (zip, area_id, state_code) IN
                       (SELECT zip, area_id, state_code
                          FROM (SELECT /*+ parallel (a, 8) */COUNT (default_flag),
                                       zip,
                                       area_id,
                                       state_code
                                  FROM kpmg_zip5_export a
                                 WHERE     default_flag = 'N'
                                       AND state_code = i.code
                                GROUP BY zip, area_id, state_code
                                HAVING COUNT (default_flag) > 1));

        -- DATACHECK1_INZIP4_NOTIN_ZIP5
        DELETE FROM kpmg_zip4_export
         WHERE state_code = i.code and(zip, area_id) IN (SELECT DISTINCT /*+ parallel (a, 8) */zip, area_id
                                    FROM kpmg_zip4_export a
                                   WHERE state_code = i.code
                                  MINUS
                                  SELECT DISTINCT /*+ parallel (b, 8) */zip, area_id
                                    FROM kpmg_zip5_export b
                                   WHERE state_code = i.code);

         --  datacheck_inzip4_notin_zip5

        DELETE FROM kpmg_zip4_export
         WHERE state_code = i.code and (zip, state_code) IN (SELECT DISTINCT /*+ parallel (a, 8) */zip, state_code
                                       FROM kpmg_zip4_export a
                                      WHERE state_code = i.code
                                     MINUS
                                     SELECT DISTINCT /*+ parallel (b, 8) */zip, state_code
                                       FROM kpmg_zip5_export b
                                      WHERE state_code = i.code);

                --  DATACHECK_ZIP4_DUPAREA
        DELETE FROM kpmg_zip4_export
         WHERE state_code = i.code and (zip, plus4_range) IN (SELECT /*+ parallel (a, 8) */zip, plus4_range
                                        FROM kpmg_zip4_export a
                                       WHERE state_code = i.code
                                      GROUP BY zip, plus4_range
                                      HAVING COUNT (DISTINCT area_id) > 1);

        COMMIT;

        --  DATACHECK1_INZIP5_NOTIN_ZIP4
        DELETE FROM kpmg_zip5_export
         WHERE state_code = i.code and (zip, area_id) IN (SELECT DISTINCT /*+ parallel (a, 8) */zip, area_id
                                    FROM kpmg_zip5_export a
                                   WHERE state_code = i.code
                                  MINUS
                                  SELECT DISTINCT /*+ parallel (b, 8) */zip, area_id
                                    FROM kpmg_zip4_export b
                                   WHERE state_code = i.code);
        COMMIT;

        --  DATACHECK_INZIP5_NOTIN_ZIP4
        DELETE FROM kpmg_zip5_export
         WHERE state_code = i.code and (zip, state_code) IN (SELECT DISTINCT /*+ parallel (a, 8) */zip, state_code
                                       FROM kpmg_zip5_export a
                                      WHERE state_code = i.code
                                     MINUS
                                     SELECT DISTINCT /*+ parallel (b, 8) */zip, state_code
                                       FROM kpmg_zip4_export b
                                      WHERE state_code = i.code);

         COMMIT;

    END LOOP;

        delete from kpmg_export_areas_file where a_area_id in (
        SELECT DISTINCT a_area_id area_id
                                      FROM kpmg_export_areas_file a
                                     WHERE check_kpmg_atleast_3_bounds(a_unique_area) > 1
        minus
        select distinct area_id from kpmg_zip5_export
        );

            INSERT INTO kpmg_ignore_taxes
            SELECT /*+ parallel (a, 8) parallel (b, 8) */a.juris_tax_id -- , b.juris_tax_id, a.start_date, a.end_date, b.start_date, b.end_date
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
                   AND a.start_date != b.start_date;

			COMMIT;

END;
/