CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_zone_auth_32
   (runId IN OUT NUMBER)
   IS
   --<data_check id="32" name="Zone Authority Mappings orphaned" >
   dataCheckId NUMBER := -759;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_AUTH_32 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT za.zone_authority_id, dataCheckId, runId, SYSDATE
    FROM tb_zone_authorities za
    WHERE (
    NOT EXISTS (
        SELECT 1
        FROM tb_authorities a
        WHERE a.authority_id = za.authority_id
        )
    OR NOT EXISTS (
        SELECT 1
        FROM tb_zones z
        WHERE z.zone_id = za.zone_id
        )
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.zone_authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_AUTH_32 finished.',runId);
    COMMIT;
END;
 
 
/