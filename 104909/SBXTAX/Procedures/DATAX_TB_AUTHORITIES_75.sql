CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_AUTHORITIES_75"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="75" name="Authorities with FIPS Code set" >
   dataCheckId NUMBER := -648;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_75 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.region_code IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_75 finished.',runId);
    COMMIT;
END;


 
 
/