CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_125
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="125" name="Differences in .2 rules" >
   dataCheckId NUMBER := -707;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_125 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_rules rdot
    WHERE r.merchant_id = taxDataProviderId
    AND rdot.authority_id = r.authority_id
    AND r.start_date = rdot.start_date
    AND (r.rule_order||'.2') = (substr(rdot.rule_order, 0, 6) )
    AND (
        r.code != rdot.code
        or nvl(r.input_recovery_percent, 1) != nvl(rdot.input_recovery_percent, 1)
        or nvl(r.exempt_reason_code,'') != nvl(rdot.exempt_reason_code,'')
        or nvl(r.exempt,'N') != nvl(r.exempt, 'N')
        or nvl(r.end_date,'') != nvl(r.end_date,'')
        or r.calculation_method != rdot.calculation_method
        or r.rate_code != rdot.rate_code
        or r.tax_type != rdot.tax_type
        or r.local_authority_type_id != rdot.local_authority_type_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_125 finished.',runId);
    COMMIT;
END;
 
 
/