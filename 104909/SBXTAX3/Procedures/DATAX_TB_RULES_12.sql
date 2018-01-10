CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_12
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="12" name="Rules with Different Calculation Method than 9990 Rule" >
   dataCheckId NUMBER := -736;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_12 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r, tb_lookups l2
    WHERE r.merchant_id = taxDataProviderId
    AND a.name NOT LIKE 'HI%'
    AND r.authority_id = a.authority_id
    AND r.merchant_id = a.merchant_id
    AND r.rule_order != 9990
    AND l2.code_group = 'TBI_CALC_METH'
    AND l2.code = (
        SELECT r2.calculation_method
        FROM tb_rules r2
        WHERE r2.authority_id = a.authority_id
        AND r2.rule_order = 9990
        )
    AND r.calculation_method != l2.code
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_12 finished.',runId);
    COMMIT;
END;
 
 
/