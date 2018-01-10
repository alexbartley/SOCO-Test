CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_174"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
    --<data_check id="174" name="Overlapping Plus4's" >
    dataCheckId NUMBER := -796;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_174 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z1.zone_id, dataCheckId, runId, SYSDATE
    from (
    select zip.name zip, plus4.range_min, plus4.range_max, plus4.zone_id
    from tb_zones zip
    join tb_zones plus4 on (zip.zone_id = plus4.parent_zone_id)
    WHERE  zip.zone_level_id = -7
    and plus4.zone_level_id = -8
    ) z1
    join (
    select zip.name zip, plus4.range_min, plus4.range_max, plus4.zone_id
    from tb_zones zip
    join tb_zones plus4 on (zip.zone_id = plus4.parent_zone_id)
    WHERE  zip.zone_level_id = -7
    and plus4.zone_level_id = -8
    ) z2 on (z1.zip = z2.zip)
    WHERE z2.zone_id != z1.zone_id
    and    (z2.range_min <= z1.range_min
        and z2.range_max >= z1.range_min)
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z1.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_174 finished.',runId);
    COMMIT;
END;


 
 
/