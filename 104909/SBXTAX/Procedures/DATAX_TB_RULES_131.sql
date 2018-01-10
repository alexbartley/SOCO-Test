CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_131"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="131" name="Rules with Different Calculation Method than 10000 Rule" >
   dataCheckId NUMBER := -737;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_131 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM  tb_rules r, tb_lookups l, tb_lookups l2
    WHERE r.merchant_id = taxDataProviderId
    AND r.rule_order != 10000
    AND r.rule_order >= 5000
    AND r.calculation_method = l.code
    AND l.code_group = 'TBI_CALC_METH'
    AND l2.code_group = 'TBI_CALC_METH'
    AND l2.code = (
        SELECT r2.calculation_method
        FROM tb_rules r2
        WHERE r2.authority_id = r.authority_id
        AND nvl(r2.is_local, 'XX') = nvl(r.is_local, 'XX')
        AND r2.rule_order = 10000
        AND r2.end_date IS NULL
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
    VALUES ('DATAX_TB_RULES_131 finished.',runId);
    COMMIT;
END;


 
 
/