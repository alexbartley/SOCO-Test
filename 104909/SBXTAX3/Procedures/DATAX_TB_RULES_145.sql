CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_145
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="145" name="Active Rules mapped to inactive Rates">
   dataCheckId NUMBER := -667;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_145 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    JOIN tb_rates ra ON (ra.rate_code = NVL(r.rate_Code,'823970') AND r.authority_id = ra.authority_id AND r.merchant_id = ra.merchant_id)
    WHERE r.end_Date IS NULL
    AND r.merchant_id = taxDataProviderId
    AND NVL(ra.end_date,'31-dec-9999') = (
        SELECT MAX(NVL(end_date,'31-dec-9999'))
        FROM tb_rates
        WHERE authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rate_code = r.rate_code
    )
    AND NVL(r.end_date,'31-dec-9999') > NVL(ra.end_date,'31-dec-9999')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_145 finished.',runId);
    COMMIT;
END;
 
 
/