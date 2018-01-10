CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_47
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "47" name=".1 and .6 Rules without subsequent .2, .3 and .7, .8 Rules" >
   dataCheckId NUMBER := -781;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_47 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_authorities a
    WHERE r.authority_id = a.authority_id
    AND r.merchant_id = taxDataProviderId
    AND a.name not like '%RENTAL%'
    AND a.name != 'TN - STATE EXTENDED CAP'
    AND (r.rule_order like '%.1' or r.rule_order like '%.6')
    AND r.rule_order != 8888.1
    AND (
    NOT EXISTS (
        SELECT 1
        FROM tb_rules
        WHERE authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rule_order = r.rule_order + .1
        )
    OR NOT EXISTS (
        SELECT 1
        FROM tb_rules
        WHERE authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rule_order = r.rule_order + .2
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
    VALUES ('DATAX_TB_RULES_47 finished.',runId);
    COMMIT;
END;
 
 
/