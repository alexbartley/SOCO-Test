CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_157
   ( taxDataProviderId IN VARCHAR2, runId IN OUT NUMBER)
   IS
   --<data_check id="157" name="WV rules without corresponding Cascading Rules">
   dataCheckId NUMBER := -685;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_157 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT sr.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules sr
    WHERE a.merchant_id = taxDataProviderId
    AND sr.merchant_id = a.merchant_id
    AND a.authority_id = sr.authority_id
    AND a.name LIKE 'WV - STATE SALES/USE TAX'
    AND NVL(sr.rate_code,'GR') NOT LIKE 'GR%'
    AND UPPER(sr.invoice_description) NOT LIKE '%TAX HOLIDAY%'
    AND NVL(sr.is_local,'N') = 'N' 
    AND sr.product_Category_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rules cr
        WHERE sr.merchant_id = cr.merchant_id
        AND sr.authority_id = cr.authority_id
        AND cr.product_Category_id IS NOT NULL
        AND cr.product_category_id = sr.product_category_id
        AND NVL(cr.is_local,'N') = 'Y'
        AND cr.rule_id != sr.rule_id
        AND FLOOR(sr.rule_order) = FLOOR(cr.rule_order)
        AND TO_NUMBER(SUBSTR(LPAD(REVERSE(TO_CHAR(sr.rule_order)),LENGTH(cr.rule_order),'0'),1,1))+5 = TO_NUMBER(SUBSTR(LPAD(REVERSE(TO_CHAR(cr.rule_order)),5,'0'),1,1))
        AND sr.start_date = cr.start_date 
        AND NVL(sr.rate_code,'XX') = NVL(cr.rate_code,'XX')
        AND NVL(sr.exempt,'N')= NVL(cr.exempt,'N')
        AND NVL(sr.no_tax,'N')= NVL(cr.no_tax,'N')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = sr.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_157 finished.',runId);
    COMMIT;
END;
 
 
/