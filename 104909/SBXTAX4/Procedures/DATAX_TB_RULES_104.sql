CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_104"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="104" name="Non-10000 Rules without Tax Type, Product, Tax Code, or Exempt Reason" >
   dataCheckId NUMBER := -741;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_104 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r,  tb_authorities a
    WHERE r.merchant_id = taxDataProviderId
    AND r.authority_id = a.authority_id
    AND r.rule_order != 10000
    AND r.tax_type IS NULL
    AND r.product_category_id IS NULL
    AND r.code IS NULL
    AND r.exempt_reason_code IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_104 finished.',runId);
    COMMIT;
END;


 
 
 
/