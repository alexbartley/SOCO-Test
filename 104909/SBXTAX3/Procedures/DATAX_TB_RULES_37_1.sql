CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_37_1
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="37.1" name="Cascading Rules without corresponding Non-Cascading Rule" >
   --37_1 is for F because it does not have TB_RULES.NO_TAX
   dataCheckId NUMBER := -787;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_37_1 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT cr.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules cr
    WHERE a.merchant_id = taxDataProviderId
    AND cr.merchant_id = a.merchant_id
    AND a.authority_id = cr.authority_id
    AND a.name NOT IN ('TN - STATE EXTENDED CAP','AK - STATE')
    AND ((a.name in ('IL - STATE SALES/USE TAX', 'NC - STATE SALES/USE TAX') and cr.rule_order != 9750.5) or (a.name not in ('IL - STATE SALES/USE TAX', 'NC - STATE SALES/USE TAX')))
    AND (a.name LIKE '%- STATE%' OR a.name = 'DC - DISTRICT SALES/USE TAX')
    AND a.name NOT LIKE '%RENTAL%'
    AND cr.rule_order NOT IN (8971, 8981, 8991, 9971, 9981, 9991)
    AND NVL(cr.rate_code,'XXX') NOT LIKE '%TH%'
    AND UPPER(cr.invoice_description) NOT LIKE '%TAX HOLIDAY%'
    AND NVL(cr.is_local,'N') = 'Y'
    AND cr.product_Category_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rules sr
        WHERE sr.merchant_id = cr.merchant_id
        AND sr.authority_id = cr.authority_id
        AND sr.product_Category_id IS NOT NULL
        AND cr.product_category_id = sr.product_category_id
        AND NVL(sr.is_local,'N') = 'N'
        AND cr.rule_id != sr.rule_id
        AND FLOOR(sr.rule_order) = FLOOR(cr.rule_order)
        AND TO_NUMBER(SUBSTR(LPAD(REVERSE(TO_CHAR(sr.rule_order)),LENGTH(cr.rule_order),'0'),1,1))+5 = TO_NUMBER(SUBSTR(LPAD(REVERSE(TO_CHAR(cr.rule_order)),5,'0'),1,1))
        AND sr.start_date = cr.start_date
        AND NVL(sr.rate_code,NVL(sr.exempt,'N')) = NVL(cr.rate_code,NVL(cr.exempt,'N'))
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = cr.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_37_1 finished.',runId);
    COMMIT;
END;
 
 
/