CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_76"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="76" name="Cascading Rules with different End Date from corresponding Non-Cascading Rule" >
   dataCheckId NUMBER := -696;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_76 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r2.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r1, tb_rules r2
    WHERE r1.authority_id = r2.authority_id
    AND r1.merchant_id = r2.merchant_id
    AND r2.rule_order = r1.rule_order + 0.5
    AND NVL(r1.is_local,'N') = 'N'
    AND r1.merchant_id = taxDataProviderId
    AND nvl(r2.is_local, 'N') = 'Y'
    AND r2.code != 'INCORRECT_VALUE'
    AND r1.code != 'INCORRECT_VALUE'
    AND r2.start_date = r1.start_date
    AND nvl(r2.end_date, to_date('3000.01.01', 'YYYY.MM.DD')) != nvl(r1.end_date, to_date('3000.01.01', 'YYYY.MM.DD'))
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r2.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_76 finished.',runId);
    COMMIT;
END;


 
 
 
/