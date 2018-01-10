CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_118"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="118" name="Differences in .1 Rules" >
   dataCheckId NUMBER := -706;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_118 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_rules rdot
    WHERE r.merchant_id = taxDataProviderId
    AND r.merchant_id = rdot.merchant_id
    AND r.authority_id = rdot.authority_id
    AND r.start_date = rdot.start_date
    AND (r.rule_order||'.1') = (SUBSTR(rdot.rule_order, 0, 6) )
    AND (
        r.code != rdot.code
        OR NVL(r.input_recovery_percent, 1) != NVL(rdot.input_recovery_percent, 1)
        OR NVL(r.exempt_reason_code,'') != NVL(rdot.exempt_reason_code,'')
        OR NVL(r.exempt,'N') != NVL(r.exempt, 'N')
        OR NVL(r.end_date,'') != NVL(r.end_date,'')
        OR r.calculation_method != rdot.calculation_method
        OR r.rate_code != rdot.rate_code
        OR r.tax_type != rdot.tax_type
        OR r.local_authority_type_id != rdot.local_authority_type_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_118 finished.',runId);
    COMMIT;
END;


 
 
/