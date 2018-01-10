CREATE OR REPLACE PROCEDURE sbxtax2.DATAX_TB_ZONES_109
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="109" name="Zones without an Authority Mapping" >
   dataCheckId NUMBER := -719;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_109 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.merchant_id = taxDataProviderId
    AND z.zone_level_id = -1
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zone_authorities za
        WHERE z.zone_id = za.zone_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_109 finished.',runId);
    COMMIT;
END;
 
 
/