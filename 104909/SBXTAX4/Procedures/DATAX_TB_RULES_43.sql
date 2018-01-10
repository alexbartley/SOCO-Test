CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_43"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="43" name="Rules with Incorrect Start Dates" >
   dataCheckId NUMBER := -657;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_43 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE a.authority_id = r.authority_id
    AND r.merchant_id = taxDataProviderId
    AND r.rate_code in ('CU', 'NL', 'ST', 'SU', 'MMCU', 'MMST', 'MMSU')
    AND r.rule_order in (5000, 9970, 9980, 9990, 5001, 9971, 9981, 9991, 8970, 8980, 8990, 8971, 8981, 8991)
    AND r.start_date > to_date('2000.01.01', 'YYYY.MM.DD')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_43 finished.',runId);
    COMMIT;
END;


 
 
 
/