CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_AUTHORITIES_133"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="133" name="EU Authorities without ZR 5000 Rule">
   dataCheckId NUMBER := -721;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_133 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND simple_registration_mask like '%EU'
    AND a.name != 'No Content'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rules r
        WHERE r.authority_id = a.authority_id
        AND r.merchant_id = a.merchant_id
        AND r.rate_code = 'ZR'
        AND r.rule_order = 5000 AND r.end_date IS NULL
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_133 finished.',runId);
    COMMIT;
END;


 
 
/