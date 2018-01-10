CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_77" (taxdataproviderid   IN     NUMBER,
                               runid               IN OUT NUMBER)
IS
    datacheckid   NUMBER := -699;
    vcnt          NUMBER := 0;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_77 started.', runid)
    RETURNING run_id
      INTO runid;

    COMMIT;

    FOR i
        IN (SELECT r.rule_id
            FROM tb_rules r
            WHERE     r.merchant_id = taxdataproviderid
                  AND EXISTS
                          (SELECT 1
                             FROM tb_rules r2
                            WHERE     r2.rule_order = r.rule_order
                                  AND r2.authority_id = r.authority_id
                                  AND r2.start_date = r.start_date
                                  AND r2.merchant_id = r.merchant_id
                                  AND r2.product_category_id =
                                          r.product_category_id
                                  AND NVL (r2.is_local, 'N') =
                                          NVL (r.is_local, 'N')
                                  AND r.rule_id > r2.rule_id))
    LOOP
        SELECT COUNT (1)
          INTO vcnt
          FROM datax_check_output
         WHERE data_check_id = datacheckid AND primary_key = i.rule_id;

        IF vcnt = 0
        THEN
            INSERT INTO datax_check_output (primary_key,
                                            data_check_id,
                                            run_id,
                                            creation_date)
            VALUES (i.rule_id,
                    datacheckid,
                    runid,
                    SYSDATE);
        END IF;
    END LOOP;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_77 finished.', runid);

    COMMIT;
END;
 
/