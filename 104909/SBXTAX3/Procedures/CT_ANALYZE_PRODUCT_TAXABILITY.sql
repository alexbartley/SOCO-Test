CREATE OR REPLACE PROCEDURE sbxtax3.ct_analyze_product_taxability(taxDataProvider IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    merchantId NUMBER;
    startTime DATE := SYSDATE;
BEGIN
    SELECT merchant_id
    INTO merchantId
    FROM tb_merchants
    WHERE name = taxDataProvider;

MERGE INTO pt_product_taxability pt
USING (
    SELECT merchant_id, primary_key, authority_id, tax_type, product_group_id, min(rule_order) rule_order
    FROM (
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_2_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_3_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_4_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_5_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_6_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_7_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_8_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
        UNION
        SELECT r.merchant_id, primary_key, r.rule_order, r.authority_id, r.tax_type, pc.product_group_id
        FROM tb_rules r, ct_product_tree pt, tb_product_categories pc
        WHERE r.product_category_id = pt.product_9_id
        AND r.end_Date IS NULL
        AND NVL(r.is_local,'N') = 'N'
        AND pc.product_category_id = pt.primary_key
        AND r.merchant_id = merchantId 
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE q.rule_id = r.rule_id
            )
    )
    GROUP BY merchant_id, primary_key, authority_id, tax_type, product_group_id
) curr ON (curr.merchant_id = pt.merchant_id
    AND curr.primary_key = pt.primary_key
    AND curr.authority_id = pt.authority_id
    AND NVL(curr.tax_type,'ANY') =  NVL(pt.tax_type,'ANY')
    )
WHEN MATCHED THEN
    UPDATE SET pt.rule_order = curr.rule_order, updated_date = SYSDATE
    WHERE pt.rule_order != curr.rule_order
WHEN NOT MATCHED THEN
    INSERT (pt.merchant_id, pt.primary_key, pt.authority_id, pt.tax_type, pt.product_group_id, pt.rule_order, pt.updated_date)
    VALUES (curr.merchant_id, curr.primary_key, curr.authority_id, curr.tax_type, curr.product_group_id, curr.rule_order, SYSDATE);

DELETE FROM pt_product_taxability
WHERE updated_date < startTime;
COMMIT;

MERGE INTO pt_catch_all
USING (
    SELECT DISTINCT r.merchant_id, pc.product_Category_id, r.tax_type, a.name authority, pc.product_group_id, a.product_group_id auth_default_product_group, 
        CASE WHEN r.rate_Code IS NOT NULL THEN r.rate_code 
        WHEN NVL(r.exempt,'N') = 'Y' THEN 'E' 
        WHEN NVL(r.no_tax,'N') = 'Y' THEN 'N' END taxability
    FROM tb_rules r, tb_product_categories pc, tb_authorities a
    WHERE r.end_Date IS NULL
    AND r.merchant_id = merchantId
    AND r.authority_id = a.authority_id
    AND r.merchant_id = pc.merchant_id
    AND pc.name = 'Product Categories'
    AND r.product_category_id IS NULL
    AND r.code IS NULL
    AND exempt_reason_Code IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rule_qualifiers q
        WHERE q.rule_id = r.rule_id
        )
) curr
ON (pt_catch_All.merchant_id = curr.merchant_id
    AND pt_catch_all.product_category_id = curr.product_category_id
    AND NVL(curr.tax_type,'ANY') = NVL(pt_catch_all.tax_type,'ANY')
    AND curr.authority = pt_catch_all.authority)
WHEN MATCHED THEN
    UPDATE SET pt_catch_all.taxability = curr.taxability, pt_catch_all.updated_date = SYSDATE
    WHERE pt_catch_all.taxability != curr.taxability
WHEN NOT MATCHED THEN
    INSERT (pt_catch_all.merchant_id, pt_catch_all.product_category_id, pt_catch_all.tax_type, pt_catch_all.authority, pt_catch_all.product_Group_id, pt_catch_all.auth_default_product_group, pt_catch_all.taxability, pt_Catch_All.updated_date)
    VALUES (curr.merchant_id, curr.product_category_id, curr.tax_type, curr.authority, curr.product_Group_id, curr.auth_default_product_group, curr.taxability, SYSDATE);

DELETE FROM pt_catch_all
WHERE updated_date < startTime;
COMMIT;

EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_ANALYZE_PRODUCT_TAXABILITY',SYSDATE,loggingMessage);
    
END; -- Procedure
 
 
/