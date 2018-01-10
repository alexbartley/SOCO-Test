CREATE OR REPLACE PROCEDURE sbxtax2.DATAX_TB_PRODUCT_CAT_123
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="123" name="Duplicate Products">
   dataCheckId NUMBER := -647;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_PRODUCT_CAT_123 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT primary_key, dataCheckId, runId, SYSDATE
        FROM (
        select pt.primary_key, COUNT(*) OVER (PARTITION BY pt.product_1_name, pt.product_2_name, pt.product_3_name, pt.product_4_name,
            pt.product_5_name, pt.product_6_name, pt.product_7_name, pt.product_8_name, pt.product_9_name, pt.product_10_name, pt.product_group_id) count_of
        FROM ct_product_tree pt
        WHERE merchant_id = taxDataProviderId
        )
    WHERE count_of > 1
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_PRODUCT_CAT_123 finished.',runId);
    COMMIT;
END;
 
 
/