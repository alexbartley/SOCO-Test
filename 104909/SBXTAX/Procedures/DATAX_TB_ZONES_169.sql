CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_169"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -791;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_169 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT z.primary_key, dataCheckId, runId, SYSDATE
    from ct_zone_tree z
    where z.code_fips is null
    and z.zone_2_name is not null
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_169 finished.',runId);
    COMMIT;
END;


 
 
/