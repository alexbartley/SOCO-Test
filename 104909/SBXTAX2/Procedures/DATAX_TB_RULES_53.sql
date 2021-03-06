CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_53
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "53" name="Rule Invoice Descriptions with Trailing Spaces" >
   dataCheckId NUMBER := -775;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_53 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    from tb_authorities a, tb_rules r
    where r.merchant_id = taxDataProviderId
    AND a.merchant_id = r.merchant_id
    AND r.authority_id = a.authority_id
    AND (r.invoice_description LIKE '% ' OR r.invoice_description LIKE ' %')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_53 finished.',runId);
    COMMIT;
END;
 
 
/