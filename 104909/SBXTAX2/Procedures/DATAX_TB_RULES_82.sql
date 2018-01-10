CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_82
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="82" name=".1, .2, .3 AND .6, .7, .8 not all Exempt or not all Non-Exempt" >
   dataCheckId NUMBER := -739;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_82 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r1.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r1, tb_rules r2, tb_rules r3
    WHERE r1.merchant_id = taxDataProviderId
    AND r1.authority_id = r2.authority_id
    AND r1.merchant_id = r2.merchant_id
    AND r2.authority_id = r3.authority_id
    AND r2.merchant_id = r3.merchant_id
    AND SUBSTR(REVERSE(TO_CHAR(r1.rule_order)),1,1) IN ('1','6')
    AND r1.rule_order like '%.%'
    AND SUBSTR(REVERSE(TO_CHAR(r2.rule_order)),1,1) IN ('2','7')
    AND r2.rule_order like '%.%'
    AND SUBSTR(REVERSE(TO_CHAR(r3.rule_order)),1,1) IN ('3','8')
    AND r3.rule_order like '%.%'
    AND SUBSTR(r2.rule_order,1,length(r2.rule_order)-1) = substr(r1.rule_order,1,length(r1.rule_order)-1)
    AND SUBSTR(r3.rule_order,1,length(r3.rule_order)-1) = substr(r2.rule_order,1,length(r2.rule_order)-1)
    AND r1.start_Date = r2.start_Date
    AND r2.start_Date = r3.start_Date
    AND nvl(r1.product_category_id, 0) = nvl(r2.product_category_id, 0)
    AND nvl(r2.product_category_id, 0) = nvl(r3.product_category_id, 0)
    AND nvl(r1.is_local, 'N') = nvl(r2.is_local, 'N')
    AND nvl(r2.is_local, 'N') = nvl(r3.is_local, 'N')
    AND (nvl(r1.exempt, 'N') != nvl(r2.exempt, 'N') or nvl(r2.exempt, 'N') != nvl(r3.exempt, 'N'))
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r1.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_82 finished.',runId);
    COMMIT;
END;
 
 
/