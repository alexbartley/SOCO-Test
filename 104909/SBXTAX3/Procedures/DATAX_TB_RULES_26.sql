CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_26
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="26" name="Rate Start Date after Rule Start Date" >
   dataCheckId NUMBER := -669;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_26 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.rate_code IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates u
        WHERE u.authority_id = r.authority_id
        AND u.rate_code = r.rate_code
        AND r.start_date >= u.start_date
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_26 finished.',runId);
    COMMIT;
END;
 
 
/