CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_69
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="69" name="Duplicate County Zones" >
   dataCheckId NUMBER := -636;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_69 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.zone_level_id = -5
    AND z.merchant_id = taxDataProviderId
    AND EXISTS (
        SELECT 1
        FROM tb_zones z3
        WHERE z3.zone_id != z.zone_id
        AND z3.name = z.name
        AND z3.parent_zone_id = z.parent_zone_id
        AND z3.merchant_id = z.merchant_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_69 finished.',runId);
    COMMIT;
END;
 
 
/