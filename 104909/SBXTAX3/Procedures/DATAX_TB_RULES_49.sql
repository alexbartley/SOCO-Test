CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_49
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "49" name=".3 and .8 Rules without preceding .1, .2 and .6, .7 Rules" >
   dataCheckId NUMBER := -779;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_49 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_authorities a
    WHERE r.authority_id = a.authority_id
    AND r.merchant_id = taxDataProviderId
    AND (r.rule_order LIKE '%.3' OR r.rule_order like '%.8')
    AND (
    NOT EXISTS (
        SELECT 1
        FROM tb_rules
        WHERE authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rule_order = r.rule_order - .1
        )
    OR NOT EXISTS (
        SELECT 1
        FROM tb_rules
        WHERE authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rule_order = r.rule_order - .2
        )
    )

    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_49 finished.',runId);
    COMMIT;
END;
 
 
/