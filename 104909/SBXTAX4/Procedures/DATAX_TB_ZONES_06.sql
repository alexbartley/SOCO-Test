CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONES_06"
   (runId IN OUT NUMBER)
   IS
    --<data_check id="06" name="Orphaned Zones" >
    dataCheckId NUMBER := -746;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_06 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z1.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z1
    WHERE z1.name != 'WORLD'
    and z1.name != 'ZONE_ID placeholder'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zones z2
        WHERE z2.zone_id = z1.parent_zone_id
        AND z2.merchant_id = z1.merchant_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z1.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_06 finished.',runId);
    COMMIT;
END;
 
/