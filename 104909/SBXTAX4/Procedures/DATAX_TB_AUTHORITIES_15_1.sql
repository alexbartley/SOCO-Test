CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_15_1"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="15.1" name="Authority Categories with Excessive Spaces" >
   dataCheckId NUMBER := -677;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_15_1 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND (a.authority_category like '% ' or a.authority_category like ' %' or a.authority_category like '%  %')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_15_1 finished.',runId);
    COMMIT;
END;


 
 
 
/