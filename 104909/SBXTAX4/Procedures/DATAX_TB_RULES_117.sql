CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_117"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="117" name="Duplicate Product Rules" >
   dataCheckId NUMBER := -708;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_117 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r,tb_rules r2
    WHERE r.merchant_id = taxDataProviderId
    AND r.authority_id = r2.authority_id
    AND r2.merchant_id = r.merchant_id
    AND r.product_category_id = r2.product_category_id
    AND r.end_date IS NULL
    AND r2.end_date IS NULL
    AND NVL (r.tax_type, 'aaa') = NVL (r2.tax_type, 'aaa')
    AND NVL (r.code, 'abcdefg') = NVL (r2.code, 'abcdefg')
    AND r2.rule_order > r.rule_order
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_117 finished.',runId);
    COMMIT;
END;


 
 
 
/