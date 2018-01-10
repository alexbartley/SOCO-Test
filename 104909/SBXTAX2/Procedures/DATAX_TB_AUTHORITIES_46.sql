CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_46
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "46" name="DC, CT, MA and VT Authorities with Cascading Product Rules for Apparel" >
   dataCheckId NUMBER := -782;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_46 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a,  tb_rules r
    WHERE a.merchant_id = taxDataProviderId
    AND r.authority_id = a.authority_id
    AND r.merchant_id = a.merchant_id
    AND NVL(r.is_local,'N') = 'Y'
    AND r.rule_order NOT IN (9971, 9981, 9991)
    AND (
        a.name IN ('DC - DISTRICT SALES/USE TAX', 'CT - STATE SALES/USE TAX', 'MA - STATE SALES/USE TAX')
        OR (
        a.name = 'VT - STATE SALES/USE TAX'
        AND r.product_category_id IN (
            SELECT DISTINCT primary_key
            FROM ct_product_tree
            WHERE product_2_name = '53 Apparel, Luggage, Personal Care Products'
            )
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
    VALUES ('DATAX_TB_AUTHORITIES_46 finished.',runId);
    COMMIT;
END;
 
 
/