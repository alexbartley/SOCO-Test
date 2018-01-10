CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_13"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="13" name="Hawaii is Special" >
   dataCheckId NUMBER := -700;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_13 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r, tb_lookups l2
    WHERE r.merchant_id = taxDataProviderId
    AND a.name LIKE 'HI%'
    AND r.authority_id = a.authority_id
    AND r.merchant_id = a.merchant_id
    AND r.rule_order NOT IN (9990, 9991, 9980, 9981)
    AND l2.code_group = 'TBI_CALC_METH'
    AND l2.code = (
        SELECT r2.calculation_method
        FROM tb_rules r2
        WHERE r2.authority_id = a.authority_id
        AND r2.rule_order = 9970
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
    VALUES ('DATAX_TB_RULES_13 finished.',runId);
    COMMIT;
END;


 
 
 
/