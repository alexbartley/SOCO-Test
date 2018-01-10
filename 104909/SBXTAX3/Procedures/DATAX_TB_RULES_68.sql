CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_68
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="68" name="Cascading Rules without Cascading Rate" >
   dataCheckId NUMBER := -725;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_68 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ru.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules ru
    WHERE ru.merchant_id = taxDataProviderId
    AND ru.rate_code NOT IN ('SU', 'CU', 'ST', 'NL', 'MMCU', 'MMSU', 'MMST')
    AND NVL(ru.is_local, 'N') = 'Y'
    AND NVL(ru.exempt, 'N') = 'N'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates ra
        WHERE ra.authority_id = ru.authority_id
        AND ru.rate_code = ra.rate_code
        AND NVL(ra.is_local, 'N') = 'Y'
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ru.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_68 finished.',runId);
    COMMIT;
END;
 
 
/