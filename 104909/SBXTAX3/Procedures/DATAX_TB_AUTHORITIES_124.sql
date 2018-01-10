CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_124
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="124" name="Authorities missing Full Registration Masks" >
   dataCheckId NUMBER := -729;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_124 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.simple_registration_mask NOT LIKE '%' || a.registration_mask || '%'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_124 finished.',runId);
    COMMIT;
END;
 
 
/