CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_86
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="86" name="Duplicate Active Rule Orders" >
   dataCheckId NUMBER := -753;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_86 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r
    JOIN  (
        SELECT r.merchant_id, r.authority_id, r.rule_order
        FROM tb_rules r
        WHERE r.merchant_id = taxDataProviderId
        AND r.end_Date IS NULL
        GROUP BY r.merchant_id, r.authority_id, r.rule_order
        HAVING COUNT(*) > 1
    ) dupeRules ON (dupeRules.authority_id = r.authority_id AND dupeRules.rule_order = r.rule_order AND dupeRules.merchant_id = r.merchant_id)
    JOIN tb_authorities a on (a.authority_id = r.authority_id)
    LEFT OUTER JOIN tb_product_categories pc on (pc.product_category_id = r.product_category_id)
    WHERE NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_86 finished.',runId);
    COMMIT;
END;
 
 
/