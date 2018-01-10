CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_81
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="81" name="Exempt 9970(1), 9980(1) and 9990(1) Rules" >
   dataCheckId NUMBER := -675;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_81 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r1.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r1, tb_rules r2, tb_rules r3
    where r1.merchant_id = taxDataProviderId
    AND r1.authority_id = r2.authority_id
    AND r1.merchant_id = r2.merchant_id
    AND r2.authority_id = r3.authority_id
    AND r2.merchant_id = r3.merchant_id
    AND r1.rule_order in( 9970, 9971)
    AND r2.rule_order in( 9980, 9981)
    AND r3.rule_order in( 9990, 9991)
    AND r1.start_Date = r2.start_Date
    AND r2.start_Date = r3.start_Date
    AND nvl(r1.product_category_id, 0) = nvl(r2.product_category_id, 0)
    AND nvl(r2.product_category_id, 0) = nvl(r3.product_category_id, 0)
    AND nvl(r1.is_local, 'N') = nvl(r2.is_local, 'N')
    AND nvl(r2.is_local, 'N') = nvl(r3.is_local, 'N')
    AND (nvl(r1.exempt, 'N') != nvl(r2.exempt, 'N') OR nvl(r2.exempt, 'N') != nvl(r3.exempt, 'N')  )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r1.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_81 finished.',runId);
    COMMIT;
END;
 
 
/