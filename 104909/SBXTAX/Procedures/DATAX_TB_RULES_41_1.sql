CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_41_1"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="41.1" name="Rules that block Child Product Rules" >
   --41_1 is for F because it does not have TB_RULE_QUALIFIERS
   dataCheckId NUMBER := -724;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_41_1 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT childRule.rule_id, dataCheckId, runId, SYSDATE
    FROM ct_product_tree parentpc, tb_rules parentRule, ct_product_tree childpc, tb_rules childRule
    WHERE parentRule.merchant_id = taxDataProviderId
    AND childRule.merchant_id = parentRule.merchant_id
    AND parentRule.authority_id = childRule.authority_id
    AND parentRule.product_category_id = parentpc.primary_key
    AND childRule.product_category_id = childpc.primary_key
    AND nvl(parentRule.end_date,'31-DEC-9999') > childRule.start_date
    AND nvl(childRule.end_date,'31-DEC-9999') > parentRule.start_date
    AND nvl(childRule.start_date,'31-DEC-9999') != nvl(childRule.end_date,'31-DEC-9999')
    AND childRule.rule_order > parentRule.rule_order
    AND nvl(parentRule.tax_type,'xx') = nvl(childRule.tax_type,'xx')
    AND childpc.primary_key != parentpc.primary_key
    AND nvl(parentrule.is_local, 'x') = nvl(childrule.is_local, 'x')
    AND nvl(parentRule.rate_code,'xx') NOT LIKE 'TH%'
    AND decode(parentpc.primary_key,
        childpc.product_1_id,1,
        childpc.product_2_id,1,
        childpc.product_3_id,1,
        childpc.product_4_id,1,
        childpc.product_5_id,1,
        childpc.product_6_id,1,
        childpc.product_7_id,1,
        childpc.product_8_id,1,
        childpc.product_9_id,1,0) =1

    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = childRule.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_41_1 finished.',runId);
    COMMIT;
END;


 
 
/