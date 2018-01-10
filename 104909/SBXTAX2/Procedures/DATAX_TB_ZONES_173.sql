CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_zones_173
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="173" name="Unique City Defaults" >
   dataCheckId NUMBER := -795;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_173 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date)
    (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM   tb_zones z, tb_zone_levels zl
    WHERE  z.zone_level_id = zl.zone_level_id
           AND zl.name = 'City'
           AND z.merchant_id = taxDataProviderId
           AND z.name IN (
                           SELECT DISTINCT tz1.NAME
                           FROM   tb_zones tz1, tb_zone_levels zl1
                           WHERE  tz1.zone_level_id = zl1.zone_level_id
                                  AND zl1.name = 'City'
                                  AND tz1.merchant_id = taxDataProviderId
                           MINUS
                           SELECT DISTINCT tz2.NAME
                           FROM   tb_zones tz2, tb_zone_levels zl2
                           WHERE  tz2.zone_level_id = zl2.zone_level_id
                                  AND zl2.name = 'City'
                                  AND tz2.merchant_id = taxDataProviderId
                                  AND tz2.default_flag IS NOT NULL -- either N or Y
                         )
           AND NOT EXISTS (
                           SELECT 1
                           FROM  datax_check_output
                           WHERE primary_key = z.zone_id
                                 AND data_check_id = dataCheckId
                          )
    );

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_173 finished.',runId);
    COMMIT;
END;
/