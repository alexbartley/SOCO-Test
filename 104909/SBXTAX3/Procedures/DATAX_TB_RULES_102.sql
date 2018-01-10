CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_102
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="102" name="Mis-Matched ERP Tax Code and Oracle Comment" >
   dataCheckId NUMBER := -679;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_102 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_Authorities a
    WHERE r.merchant_id = taxDataProviderId
    AND r.authority_id= a.authority_id
    AND r.merchant_id = a.merchant_id
    AND r.end_date IS NULL
    AND r.rule_comment NOT LIKE ('%ORACLE['||a.erp_tax_code||']%')
    AND NOT (
        (a.name = 'Alberta' and rule_order = 8900)
        OR (a.name = 'India Maharashtra' and rule_order = 5814)
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_102 finished.',runId);
    COMMIT;
END;
 
 
/