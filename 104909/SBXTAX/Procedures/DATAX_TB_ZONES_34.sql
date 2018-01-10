CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_34"
   ( taxDataProviderId IN NUMBER,  runId IN OUT NUMBER)
   IS
   --<data_check id="34" name="Non-default Single-instance Zip Codes" >
   dataCheckId NUMBER := -668;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_34 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.merchant_id = taxDataProviderId
    AND z.zone_level_id = -7
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zones z2
        WHERE z2.name = z.name
        AND nvl(z2.default_flag, 'x') = 'Y'
        AND z.merchant_id = z2.merchant_id
    )
    /* it seems to not matter if there are multiple instances, all zips must have one default
    AND EXISTS (
        SELECT 1
        FROM (
            select name, merchant_id
            from tb_zones
            where zone_level_id = -7
            group by name, merchant_id
            having count(*) > 1
        ) multis
        WHERE multis.name = z.name
        AND multis.merchant_id = z.merchant_id
        )*/
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