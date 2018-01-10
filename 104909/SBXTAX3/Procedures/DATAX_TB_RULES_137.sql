CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rules_137
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="137" name="Cascading Rules with different Taxability from corresponding Non-Cascading Rule">
   dataCheckId NUMBER := -742;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_137 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r2.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r1, tb_rules r2
    WHERE r1.merchant_id = taxDataProviderId
    AND r2.rule_order = r1.rule_order + 0.5
    AND r1.authority_id = r2.authority_id
    AND r1.merchant_id = r2.merchant_id
    AND r2.start_date = r1.start_date
    AND NVL(r1.is_local,'N') = 'N'
    AND NVL(r2.is_local,'N') = 'Y'
    AND (
        nvl(r2.exempt, 'N') != nvl(r1.exempt, 'N')
        OR nvl(r2.rate_code, 'null') != nvl(r1.rate_code, 'null')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r2.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_137 finished.',runId);
    COMMIT;
END;
 
 
/