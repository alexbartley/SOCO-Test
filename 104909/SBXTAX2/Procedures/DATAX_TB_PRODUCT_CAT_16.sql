CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_product_cat_16
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="16" name="Products with Excessive Spaces" >
   dataCheckId NUMBER := -650;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_PRODUCT_CAT_16 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT p.product_Category_id, dataCheckId, runId, SYSDATE
    FROM tb_product_categories p
    WHERE (p.name LIKE '% ' OR p.name LIKE ' %')
    AND p.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = p.product_Category_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_PRODUCT_CAT_16 finished.',runId);
    COMMIT;
END;
 
 
/