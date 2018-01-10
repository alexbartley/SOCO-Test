CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_113"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="113" name="ZR Rules in PST Authorities that aren't in the 5000-5300 or 9800-10000 Range" >
   dataCheckId NUMBER := -695;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_113 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND a.merchant_id = r.merchant_id
    AND a.authority_id = r.authority_id
    AND r.rule_order > 5003
    AND 9800 > r.rule_order
    AND r.rate_code = 'ZR'
    AND a.invoice_description = 'PST'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_113 finished.',runId);
    COMMIT;
END;


 
 
/