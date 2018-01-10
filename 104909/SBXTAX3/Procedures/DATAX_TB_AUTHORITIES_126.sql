CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_126
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="126" name="Authorities missing TOJ option" >
   dataCheckId NUMBER := -712;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_126 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authority_requirements r
        WHERE r.authority_id = a.authority_id
        AND r.merchant_id = a.merchant_id
        AND r.name = 'TOJ'
        AND r.condition IS NULL
        AND r.value = 'N'
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_126 finished.',runId);
    COMMIT;
END;
 
 
/