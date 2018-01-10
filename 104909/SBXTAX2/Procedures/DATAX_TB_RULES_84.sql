CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_84
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="84" name="Overlapping Rules" >
   dataCheckId NUMBER := -629;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_84 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_rules r2
    WHERE r.merchant_id = taxDataProviderId
    AND r2.merchant_id = r.merchant_id
    AND r.authority_id = r2.authority_id
    AND r2.rule_id != r.rule_id
    AND r2.rule_order = r.rule_order
    AND nvl(r.end_date, to_date('9999.01.01', 'YYYY.MM.DD')) > r2.start_date
    AND r2.start_date >= r.start_date
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_84 finished.',runId);
    COMMIT;
END;
 
 
/