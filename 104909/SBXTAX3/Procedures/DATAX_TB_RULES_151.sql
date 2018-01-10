CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_151
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="151" name="Mismatched PT in SC Authorities">
   dataCheckId NUMBER := -715;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_151 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT sub.rule_id, dataCheckId, runId, SYSDATE
    FROM  (
        SELECT r.rule_id, COUNT(*) OVER (PARTITION BY r.rule_order, r.start_Date, r.product_category_id, r.rate_Code, r.exempt , r.tax_type) count_of
        FROM tb_rules r, tb_authorities a
        WHERE r.authority_id = a.authority_id
        AND a.merchant_id = r.merchant_id
        AND r.merchant_id = taxDataProviderId
        AND NVL(is_local,'N') = 'N'
        AND a.name in (
            'SC - STATE SALES/USE TAX',
            'SC - CATAWBA (YORK CO) TRIBAL SALES/USE TAX',
            'SC - CATAWBA (LANCASTER CO) TRIBAL SALES/USE TAX',
            'SC - STATE SALES/USE TAX (CATAWBA RESERVATION)'
        )
    ) sub
    WHERE count_of < 4
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = sub.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_151 finished.',runId);
    COMMIT;
END;
 
 
/