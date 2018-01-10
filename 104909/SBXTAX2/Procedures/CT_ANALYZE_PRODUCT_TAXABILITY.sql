CREATE OR REPLACE PROCEDURE sbxtax2.ct_analyze_product_taxability(taxDataProvider IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    merchantId NUMBER;
    startTime DATE := SYSDATE;
    rulesModDate DATE;
    lastAnalyzedDate DATE;
BEGIN
   INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
   VALUES ('CT_ANALYZE_PRODUCT_TAXABILITY',startTime,'Begin analysis of product taxability for '||taxDataProvider||'.');
   COMMIT;
   
    SELECT merchant_id
    INTO merchantId
    FROM tb_merchants
    WHERE name = taxDataProvider;

    SELECT MAX(last_update_date)
    INTO rulesModDate
    FROM tb_rules
    WHERE merchant_id = merchantId;
    
    SELECT MIN(analyzed_date)
    INTO lastAnalyzedDate
    FROM pt_product_taxability;
    
    IF (rulesModDate > lastAnalyzedDate OR lastAnalyzedDate IS NULL) THEN
        --Re-analyze product taxability
        DELETE FROM pt_product_taxability;
        COMMIT;
    
        INSERT INTO pt_product_taxability pt (primary_key,authority_id,tax_type,product_group_id,effective_rule_order,
            merchant_id,rate_code,exempt,no_tax,analyzed_date) (
            SELECT primary_key,authority_id,tax_type,product_group_id,effective_rule_order, merchant_id,rate_code,exempt,no_tax,SYSDATE
            FROM (
                SELECT merchant_id, primary_key, authority_id, tax_type, product_group_id, rule_order, rate_code, exempt, no_tax, 
                    MIN(rule_order) OVER (PARTITION BY primary_key, authority_id, tax_type, product_group_id) effective_rule_order
                FROM (
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_2_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_3_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_4_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_5_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_6_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_7_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_8_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                    UNION
                    SELECT r.merchant_id, primary_key, r.rule_order, r.rate_code, NVL(r.exempt,'N') exempt, NVL(r.no_tax,'N') no_tax, r.authority_id, r.tax_type, pc.product_group_id
                    FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
                    WHERE r.product_category_id = pt.product_9_id
                    AND r.end_Date IS NULL
                    AND NVL(r.is_local,'N') = 'N'
                    AND pc.product_category_id = pt.primary_key
                    AND r.merchant_id = merchantId 
                    AND r.code IS NULL
                )
            )
            WHERE rule_order = effective_rule_order
        );
        COMMIT;
    END IF;

INSERT INTO CT_PROC_LOG (procedure_name, execution_Date, message)
VALUES ('CT_ANALYZE_PRODUCT_TAXABILITY',SYSDATE,'End analysis of product taxability for '||taxDataProvider||'.');
COMMIT;

EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_ANALYZE_PRODUCT_TAXABILITY',SYSDATE,'Terminated with error: '||loggingMessage);
    
END; -- Procedure
 
 
/