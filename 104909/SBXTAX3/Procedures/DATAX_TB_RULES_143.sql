CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_143
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="143" name="Rules with invalid calculation method">
   dataCheckId NUMBER := -671;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_143 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.calculation_method NOT IN (
        SELECT l.code
        FROM tb_lookups  l
        WHERE code_group = 'TBI_CALC_METH'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_143 finished.',runId);
    COMMIT;
END;
 
 
/