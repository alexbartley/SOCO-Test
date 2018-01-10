CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONES_66"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "66" name="Duplicate +4s" >
   dataCheckId NUMBER := -762;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_66 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT geo1.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones zip1, tb_Zones zip2, tb_Zones geo1, tb_zones geo2
    WHERE zip1.zone_id = geo1.parent_zone_id
    AND zip2.zone_id = geo2.parent_zone_id
    AND zip1.name = zip2.name
    AND zip1.zone_level_id = -7
    AND zip2.zone_level_id = -7
    AND geo1.zone_id != geo2.zone_id
    AND geo1.merchant_id = geo2.merchant_id
    AND geo1.merchant_id = taxDataProviderId
    AND (
    (geo2.range_min >= geo1.range_min AND geo1.range_max >= geo2.range_min)
    or
    (geo2.range_max >= geo1.range_min AND geo1.range_max >= geo2.range_max)
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = geo1.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_66 finished.',runId);
    COMMIT;
END;


 
 
 
/