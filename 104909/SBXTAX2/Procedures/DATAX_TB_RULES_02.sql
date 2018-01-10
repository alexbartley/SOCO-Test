CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_02
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="02" name="Bad Catch-all Rules" >
   dataCheckId NUMBER := -703;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_02 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM  tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.tax_type IS NULL
    AND r.code IS NULL
    AND r.product_category_id IS NULL
    AND (r.is_local = 'N' OR r.is_local IS NULL)
    AND r.rule_order NOT IN( 10000,9990,5000,8888,9760,8888.1,8888.2,8888.3,5050,5000)
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_02 finished.',runId);
    COMMIT;
END;
 
 
/