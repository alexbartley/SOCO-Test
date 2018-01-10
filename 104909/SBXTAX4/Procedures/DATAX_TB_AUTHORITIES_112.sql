CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_112"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -738;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_112 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND NVL(a.is_template,'N') = 'N'
    AND (
        NOT EXISTS (
            SELECT 1
            FROM tb_rules r1
            WHERE r1.authority_id = a.authority_id
            AND r1.rule_order = 9970
            ) OR
        NOT EXISTS (
            SELECT 1
            FROM tb_rules r2
            WHERE r2.authority_id = a.authority_id
            AND r2.rule_order = 9980
            ) OR
        NOT EXISTS (
            SELECT 1
            FROM tb_rules r3
            WHERE r3.authority_id = a.authority_id
            AND r3.rule_order = 9990
            )
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_112 finished.',runId);
    COMMIT;
END;


 
 
 
/