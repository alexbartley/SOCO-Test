CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_121
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="121" name="Authorities with no 10000 Rule" >
   dataCheckId NUMBER := -713;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_121 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.name NOT LIKE 'Template%'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rules r
        WHERE r.authority_id = a.authority_id
        AND r.merchant_id = a.merchant_id
        AND r.rule_order = 10000
        AND r.end_date IS NULL
    )
    AND EXISTS (
        SELECT 1
        FROM tb_zone_authorities z
        WHERE z.authority_id = a.authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_121 finished.',runId);
    COMMIT;
END;
 
 
/