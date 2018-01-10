CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_PRODUCT_CAT_147"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="147" name="Duplicate Prodcodes mapped to Rules">
   dataCheckId NUMBER := -625;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_PRODUCT_CAT_147 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT pc2.product_Category_id, dataCheckId, runId, SYSDATE
    FROM tb_product_Categories pc2,  (
        SELECT pc.merchant_id, product_group_id, prodcode
        FROM tb_product_categories  pc
        WHERE prodcode IS NOT NULL
        AND pc.merchant_id = taxDataProviderId
        GROUP BY pc.merchant_id, product_Group_id, prodcode
        HAVING COUNT(*) > 1
    ) dupes
    WHERE pc2.merchant_id = dupes.merchant_id
    AND pc2.product_group_id = dupes.product_Group_id
    AND pc2.prodcode = dupes.prodcode
    AND EXISTS (
        SELECT 1
        FROM tb_rules r
        WHERE r.product_category_id = pc2.product_Category_id
        AND r.merchant_id = pc2.merchant_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = pc2.product_Category_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_PRODUCT_CAT_147 finished.',runId);
    COMMIT;
END;


 
 
/