CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_30"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="30" name="Rate Code CU without Tax Type CU" >
   dataCheckId NUMBER := -653;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_30 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.rate_code like '%CU%'
    AND nvl(r.tax_type, 'ANY') != 'CU'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_30 finished.',runId);
    COMMIT;
END;


 
 
 
/