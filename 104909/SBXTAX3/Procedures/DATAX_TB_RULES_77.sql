CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_77
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -699;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_77 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND EXISTS(
        SELECT 1
        FROM tb_rules r2
        WHERE r2.rule_order = r.rule_order
        AND r2.authority_id = r.authority_id
        AND r2.start_date = r.start_date
        AND r2.merchant_id = r.merchant_id
        AND r2.product_category_id = r.product_category_id
        AND nvl(r2.is_local, 'N') = nvl(r.is_local, 'N')
        AND r.rule_id > r2.rule_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_77 finished.',runId);
    COMMIT;
END;
 
 
/