CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RATES_78" (taxdataproviderid   IN     NUMBER,
                               runid               IN OUT NUMBER)
IS
    --<data_check id="78" name="Duplicate Rates" >
    datacheckid   NUMBER := -747;
    vcnt          NUMBER := 0;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_78 started.', runid)
    RETURNING run_id
      INTO runid;

    COMMIT;

    FOR i
        IN (SELECT r.rate_id
            FROM tb_rates r
            WHERE     r.merchant_id = taxdataproviderid
                  AND EXISTS
                          (SELECT 1
                             FROM tb_rates r2
                            WHERE     r2.rate_code = r.rate_code
                                  AND r2.authority_id = r.authority_id
                                  AND r2.start_date = r.start_date
                                  AND NVL (r2.is_local, 'N') =
                                          NVL (r.is_local, 'N')
                                  AND r.rate_id > r2.rate_id))
    LOOP
        SELECT COUNT (1)
          INTO vcnt
          FROM datax_check_output
         WHERE data_check_id = datacheckid
           AND primary_key = i.rate_id;

        IF vcnt = 0
        THEN
            INSERT INTO datax_check_output (primary_key,
                                            data_check_id,
                                            run_id,
                                            creation_date)
            VALUES (i.rate_id,
                    datacheckid,
                    runid,
                    SYSDATE);
        END IF;
    END LOOP;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_78 finished.', runid);

    COMMIT;
END;
 
/