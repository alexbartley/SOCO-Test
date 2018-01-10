CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_09"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="09" name="Rules without Rule Comment" >
   dataCheckId NUMBER := -752;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_09 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    -- hack to prevent results from running too long for Telco
    /*INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.rule_comment IS NULL
    AND r.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );*/
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_09 finished.',runId);
    COMMIT;
END;
 
/