CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_48"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "48" name=".2 and .7 Rules without partnering .1, .3 and .6, .8 Rules" >
   dataCheckId NUMBER := -780;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_48 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_authorities a
    WHERE r.authority_id = a.authority_id
    AND a.name NOT LIKE '%RENTAL%'
    AND r.merchant_id = taxDataProviderId
    AND (r.rule_order LIKE '%.2' OR r.rule_order LIKE '%.7')
    AND r.rule_order != 8888.2
    AND (
    NOT EXISTS (
        SELECT 1
        FROM tb_rules
        where authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rule_order = r.rule_order + .1
        )
    OR NOT EXISTS (
        SELECT 1
        FROM tb_rules
        WHERE authority_id = r.authority_id
        AND merchant_id = r.merchant_id
        AND rule_order = r.rule_order - .1
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
    VALUES ('DATAX_TB_RULES_48 finished.',runId);
    COMMIT;
END;


 
 
 
/