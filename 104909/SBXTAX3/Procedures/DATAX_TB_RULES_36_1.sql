CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_36_1
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="36.1" name="State Level Product Rules without correct (Product Rule Order + .5) Cascading Rule" >
   --36_1 is for F because it does not have TB_RULES.NO_TAX
   dataCheckId NUMBER := -786;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_36_1 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_authorities a
    WHERE r.merchant_id = taxDataProviderId
    AND a.merchant_id = r.merchant_id
    AND a.authority_id = r.authority_id
    AND a.name LIKE '%- STATE%'
    AND (
        (a.name = 'VT - STATE SALES/USE TAX' AND r.rule_order NOT LIKE '7%')
        OR (a.name NOT LIKE 'VT%')
        )
    AND a.name not like '%RENTAL%'
    AND r.rule_order not in (5000, 9970, 9980, 9990, 8970, 8980, 8990, 9751, 9752, 9753)
    AND NVL(r.rate_code,'XXX') NOT LIKE '%TH%'
    AND UPPER(r.invoice_description) NOT LIKE '%TAX HOLIDAY%'
    AND NVL(r.is_local,'N') = 'N'
    AND r.product_category_id IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM tb_rules r2
        WHERE r2.authority_id = r.authority_id
        AND r2.merchant_id = r.merchant_id
        AND NVL(r2.is_local,'N') = 'Y'
        )
    AND EXISTS (
        SELECT 1 --Has a Cascading PT Rule for same product as State PT Rule
        FROM tb_rules r2
        WHERE r2.authority_id = r.authority_id
        AND r2.merchant_id = r.merchant_id
        AND NVL(r2.is_local,'N') = 'Y'
        AND r2.product_category_id IS NOT NULL
        AND r2.product_Category_id = r.product_Category_id
        )
    AND NOT EXISTS (
        SELECT 1 --But the Cascading PT Rule does not match the State PT Rule
        FROM tb_rules r2
        WHERE r2.authority_id = r.authority_id
        AND r2.merchant_id = r.merchant_id
        AND r2.start_date = r.start_date
        AND FLOOR(r.rule_order) = FLOOR(r2.rule_order)
        AND TO_NUMBER(SUBSTR(LPAD(REVERSE(TO_CHAR(r.rule_order)),LENGTH(r2.rule_order),'0'),1,1))+5 = TO_NUMBER(SUBSTR(LPAD(REVERSE(TO_CHAR(r2.rule_order)),5,'0'),1,1))
        AND NVL(r2.product_category_id,-22222) = NVL(r.product_category_id,-22222)
        AND NVL(r2.exempt,'N') = NVL(r.exempt,'N')
        AND NVL(r2.rate_code,'N') = NVL(r.rate_code,'N')
        --AND NVL(r2.no_tax,'N') = NVL(r.no_tax,'N') --Not in F
        AND NVL(r2.is_local,'N') = 'Y'
        )
    AND NOT EXISTS (
        SELECT 1 --Exclude Rules that are part of a Tax Holiday
        FROM tb_rules r2
        WHERE r2.authority_id = r.authority_id
        AND r2.merchant_id = r.merchant_id
        AND r2.start_Date = r.start_Date
        AND r2.end_date IS NOT NULL
        AND NVL(r2.end_date,'31-Dec-9999') = r.end_date
        AND NVL(r2.is_local,'N') = NVL(r.is_local,'N')
        AND (NVL(r2.rate_code,'XXX') LIKE '%TH%' OR UPPER(r.invoice_description) LIKE '%TAX HOLIDAY%')
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_36_1 finished.',runId);
    COMMIT;
END;
 
 
/