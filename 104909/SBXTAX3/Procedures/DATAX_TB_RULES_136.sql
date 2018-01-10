CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_136
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="136" name="Rules Mapped to Norway or India Products">
   dataCheckId NUMBER := -674;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_136 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_product_categories pc, tb_product_groups pg
    WHERE r.product_category_id = pc.product_category_id
    AND pg.product_group_id = pc.product_group_id
    AND pg.name IN ('Norway','India')
    AND r.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_136 finished.',runId);
    COMMIT;
END;
 
 
/