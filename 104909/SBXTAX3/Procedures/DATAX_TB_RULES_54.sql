CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_54
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "54" name="Rule Rate Codes with Trailing Spaces" >
   dataCheckId NUMBER := -774;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_54 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND a.merchant_id = r.merchant_id
    AND r.authority_id = a.authority_id
    AND (r.rate_code LIKE '% ' OR r.rate_code LIKE ' %')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_54 finished.',runId);
    COMMIT;
END;
 
 
/