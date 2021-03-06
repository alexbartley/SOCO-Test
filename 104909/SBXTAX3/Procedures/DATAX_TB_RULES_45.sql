CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_45
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "45" name="ST Rules with non-null Tax Type" >
   dataCheckId NUMBER := -783;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_45 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE a.authority_id = r.authority_id
    AND r.merchant_id = taxDataProviderId
    AND r.rate_code like '%ST%'
    AND r.tax_type is not null
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_45 finished.',runId);
    COMMIT;
END;
 
 
/