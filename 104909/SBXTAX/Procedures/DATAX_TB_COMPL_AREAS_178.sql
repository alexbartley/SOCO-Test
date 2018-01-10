CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_COMPL_AREAS_178"
(runId IN OUT NUMBER)
is
   --<data_check id="178" name="Check for compliance areas associated with the same Authorities with overlapping date range" >
   dataCheckId NUMBER := -800;
   vlocal_step varchar2(100);
   err_num number;
   err_msg varchar2(4000);
begin

    vlocal_step := 'DATAX_TB_COMPL_AREAS_178 STEP 0:';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_178 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    vlocal_step := 'DATAX_TB_COMPL_AREAS_178 STEP 1:';
    -- different compliance areas that were associated with the same list of authorities with overlapping date range
    insert into datax_check_output(step_info, primary_key, data_check_id, run_id, creation_date)
    (
                    SELECT vlocal_step || ' Authorities List: ' || auth_list,
                           compliance_area_id,
                           datacheckid,
                           runid,
                           SYSDATE
                      FROM (WITH min_comp
                                     AS (SELECT auth_list,
                                                min_comp_area comp_area_id,
                                                b.start_date,
                                                b.end_date,
                                                b.NAME
                                           FROM (SELECT auth_list, min_comp_area
                                                   FROM (SELECT auth_list,
                                                                MIN (compliance_area_id)
                                                                    min_comp_area,
                                                                MAX (compliance_area_id)
                                                                    max_comp_area
                                                           FROM (SELECT LISTAGG (
                                                                            authority_id,
                                                                            ',')
                                                                        WITHIN GROUP (ORDER BY
                                                                                          t1.compliance_area_id)
                                                                            auth_list,
                                                                        t1.compliance_area_id
                                                                   FROM tb_comp_area_authorities t1
                                                                 GROUP BY t1.compliance_area_id
                                                                 HAVING COUNT (
                                                                            t1.compliance_area_id) >
                                                                            1)
                                                         GROUP BY auth_list)
                                                  WHERE min_comp_area != max_comp_area) a,
                                                tb_compliance_areas b
                                          WHERE a.min_comp_area = b.compliance_area_id),
                                 all_comp
                                     AS (SELECT *
                                           FROM (SELECT LISTAGG (
                                                            authority_id,
                                                            ',')
                                                        WITHIN GROUP (ORDER BY
                                                                          t1.compliance_area_id)
                                                            auth_list,
                                                        t2.compliance_area_id,
                                                        t2.start_date,
                                                        t2.end_date,
                                                        t2.name
                                                   FROM tb_comp_area_authorities t1,
                                                        tb_compliance_areas t2
                                                  WHERE t1.compliance_area_id =
                                                            t2.compliance_area_id
                                                 GROUP BY t2.compliance_area_id,
                                                          t2.start_date,
                                                          t2.end_date,
                                                          t2.name
                                                 HAVING COUNT (t2.compliance_area_id) > 1))
                            SELECT c1.auth_list, c1.comp_area_id, c2.compliance_area_id
                              FROM min_comp c1, all_comp c2
                             WHERE     c1.auth_list = c2.auth_list
                                   AND c1.comp_area_id <> c2.compliance_area_id -- crapp-3055
                                   AND c1.start_date BETWEEN c2.start_date
                                                         AND NVL (c2.end_date, '31-dec-9999')
                                   AND ('%'||c1.NAME||'%' LIKE c2.NAME -- crapp-3055
                                        OR '%'||c2.NAME||'%' LIKE c1.NAME
                                       )
                                   AND NVL (c1.end_date, '31-dec-9999') BETWEEN c2.start_date
                                                                            AND NVL (
                                                                                    c2.end_date,
                                                                                    '31-dec-9999')
                            GROUP BY c1.comp_area_id, c1.auth_list, c2.compliance_area_id
                            ORDER BY c1.auth_list DESC, c2.compliance_area_id) a
                     WHERE NOT EXISTS
                               (SELECT 1
                                  FROM datax_check_output
                                 WHERE     primary_key = a.compliance_area_id
                                       AND data_check_id = -800)
    );

    vlocal_step := 'DATAX_TB_COMPL_AREAS_178 STEP 2:';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_178 finished.',runId);
    COMMIT;

EXCEPTION
WHEN OTHERS THEN
      ROLLBACK;
      err_num := SQLCODE;
      err_msg := SUBSTR(SQLERRM, 1, 4000);

    INSERT INTO data_check_err_log(dataCheckId, runId, errcode, errmsg, step_number, entered_date, entered_by)
    VALUES( dataCheckId, runId, err_num, err_msg, vlocal_step, SYSDATE, -1);
    COMMIT;
END;
/