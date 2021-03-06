CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_116"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="116" name="9990-9999 Rules that don't match pattern" >
   dataCheckId NUMBER := -727;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_116 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.rule_order > 9990
    AND r.rule_order !=   10000
    AND r.end_date IS NULL
    AND (
        (r.rate_code IS NOT NULL AND r.code IS NULL)
        OR (r.exempt = 'Y' AND r.code IS NULL)
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_116 finished.',runId);
    COMMIT;
END;


 
 
/