CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_140
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="140" name="Non-10000 Rules missing Tax Type">
   dataCheckId NUMBER := -718;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_140 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.rule_order != 10000
    AND r.tax_type is null
    AND r.product_category_id is null
    AND r.code is null
    AND r.exempt_reason_code is null
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_140 finished.',runId);
    COMMIT;
END;
 
 
/