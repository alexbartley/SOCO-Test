CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_34
   ( taxDataProviderId IN NUMBER,  runId IN OUT NUMBER)
   IS
   --<data_check id="34" name="Non-default Single-instance Zip Codes" >
   dataCheckId NUMBER := -668;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_34 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.merchant_id = taxDataProviderId
    AND z.zone_level_id = -7
    AND nvl(z.default_flag, 'x') != 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zones z2
        WHERE z2.name = z.name
        AND z2.zone_id != z.zone_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_34 finished.',runId);
    COMMIT;
END;
 
 
/