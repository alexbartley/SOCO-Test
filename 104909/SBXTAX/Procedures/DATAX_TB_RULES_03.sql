CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_03"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="03" name="Rules with no Authority">
   dataCheckId NUMBER := -751;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_03 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ru.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules ru
    WHERE ru.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authorities ra
        WHERE ra.authority_id = ru.authority_id
        AND ra.merchant_id = ru.merchant_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ru.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_03 finished.',runId);
    COMMIT;
END;


 
 
/