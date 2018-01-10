CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_153
   ( taxDataProviderId IN NUMBER,  runId IN OUT NUMBER)
   IS
   --<data_check id="153" name="Tax Holiday Rules with Rule Qualifiers and Tax Code or Exempt Reason">
   dataCheckId NUMBER := -740;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_153 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_authorities a, tb_merchants m, tb_rule_qualifiers q
    WHERE r.merchant_id = taxDataProviderId
    AND (nvl(r.code,'xx') = 'HOLIDAY' OR nvl(r.exempt_reason_code,'xx') = 'HOLIDAY')
    AND q.rule_id = r.rule_id
    AND nvl(r.rate_code,'xx') NOT LIKE 'TH%'
    AND r.start_date > SYSDATE-1
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_153 finished.',runId);
    COMMIT;
END;
 
 
/