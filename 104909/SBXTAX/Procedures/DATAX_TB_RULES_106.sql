CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_106"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="106" name="10000 Rules Attached to Products" >
   dataCheckId NUMBER := -717;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_106 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_product_categories p, tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.product_category_id = p.product_category_id
    AND r.merchant_id = p.merchant_id
    AND r.rule_order = 10000
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_106 finished.',runId);
    COMMIT;
END;


 
 
/