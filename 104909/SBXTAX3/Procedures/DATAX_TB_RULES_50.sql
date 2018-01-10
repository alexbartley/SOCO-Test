CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_50
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "50" name="Rules with malformed Oracle Comments" >
   dataCheckId NUMBER := -778;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_50 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE r.authority_id = a.authority_id
    AND a.merchant_id = r.merchant_id
    AND a.name NOT LIKE 'US%'
    AND r.merchant_id = taxDataProviderId
    AND r.rule_comment NOT LIKE 'ORACLE[US' || substr(a.name, 0, 2) || ']%'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_50 finished.',runId);
    COMMIT;
END;
 
 
/