CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_07
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="07" name="Auths with no Zone" >
   dataCheckId NUMBER := -701;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_07 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Checking for detached mappings for DATAX_TB_AUTHORITIES_07.',runId);
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND NVL(a.is_template, 'N') != 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zone_authorities za
        WHERE a.authority_id = za.authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Checking for newly attached mappings for DATAX_TB_AUTHORITIES_07.',runId);
    COMMIT;
    UPDATE datax_check_output dco
    SET removed = 'Y', reviewed_Approved = NULL, verified = NULL
    WHERE data_check_id = dataCheckId
    AND NVL(removed,'N') = 'N'
    AND EXISTS (
        SELECT 1
        FROM tb_zone_authorities za
        WHERE dco.primary_key = za.authority_id
        );
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Checking for newly UN-mappings for DATAX_TB_AUTHORITIES_07.',runId);
    COMMIT;
    UPDATE datax_check_output dco
    SET removed = NULL, reviewed_Approved = NULL, approved_date = NULL, verified = NULL, verified_date = NULL
    WHERE data_check_id = dataCheckId
    AND NVL(removed,'N') = 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zone_authorities za
        WHERE dco.primary_key = za.authority_id
        );
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_07 finished.',runId);
    COMMIT;

END;
 
 
/