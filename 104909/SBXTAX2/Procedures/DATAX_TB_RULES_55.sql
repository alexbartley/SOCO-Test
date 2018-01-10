CREATE OR REPLACE PROCEDURE sbxtax2.DATAX_TB_RULES_55
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "55" name="Rules with no Invoice Description" >
   dataCheckId NUMBER := -773;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_55 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.invoice_description IS NULL
    AND r.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authorities a
        WHERE a.name LIKE 'Brazil%'
        AND a.merchant_id = r.merchant_id
        AND a.authority_id = r.authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_55 finished.',runId);
    COMMIT;
END;
 
 
/