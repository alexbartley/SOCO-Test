CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_01"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="01" name="Rules with no Rates">
   dataCheckId NUMBER := -632;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_01 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ru.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules ru
    WHERE ru.merchant_id = taxDataProviderId
    AND (ru.exempt = 'N' OR ru.exempt IS NULL)
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates ra
        WHERE ra.authority_id = ru.authority_id
        AND ra.merchant_id = ru.merchant_id
        AND ru.rate_code = ra.rate_code
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ru.rule_id
        AND data_check_id = dataCheckId
        AND reviewed_Approved IS NOT NULL
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_01 finished.',runId);
    COMMIT;
END;


 
 
 
/