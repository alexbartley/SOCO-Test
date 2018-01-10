CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_38
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="38" name="Authorities missing 5000 Rule" >
   dataCheckId NUMBER := -646;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_38 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND nvl(a.is_template, 'N') != 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rules r
        WHERE r.rule_order = 5000
        AND r.authority_id = a.authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key =  a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_38 finished.',runId);
    COMMIT;
END;
 
 
/