CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_40"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="40" name="Cascading Rules with different Start Date from corresponding Non-Cascading Rule" >
   dataCheckId NUMBER := -697;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_40 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r1.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r1, tb_rules r2
    WHERE r1.merchant_id = r2.merchant_id
    AND r1.authority_id = r2.authority_id
    AND r1.merchant_id = taxDataProviderId
    AND r2.is_local = 'Y'
    AND r2.start_date > r1.start_date
    AND r2.rule_order = r1.rule_order + 0.5
    AND r1.is_local IS NULL
    AND nvl(r2.end_date, TO_DATE('9999.01.01', 'YYYY.MM.DD')) = nvl(r1.end_date, TO_DATE('9999.01.01', 'YYYY.MM.DD'))
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r1.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_40 finished.',runId);
    COMMIT;
END;


 
 
/