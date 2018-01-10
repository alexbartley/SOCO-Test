CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_114"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="114" name="Oracle Rule Comments that are too long" >
   dataCheckId NUMBER := -726;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_114 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.end_date IS NULL
    AND LENGTH(TRIM(SUBSTR(r.rule_comment,INSTR(r.rule_comment, '[')+1, INSTR(r.rule_comment, ']')-INSTR(r.rule_comment, '[')-1))) != 5
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_114 finished.',runId);
    COMMIT;
END;


 
 
 
/