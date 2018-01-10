CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONES_95"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="95" name="Multi-County Cities without Default" >
   dataCheckId NUMBER := -665;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_95 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z, tb_zones z2, tb_zones z3
    WHERE z.merchant_id = taxDataProviderId
    AND z.parent_zone_id = z2.zone_id
    AND z2.parent_zone_id = z3.zone_id
    AND z.zone_level_id = -6
    AND z.name not in ('UNINCORPORATED','UNKNOWN')
    AND NVL(z.default_flag, 'N') = 'N'
    AND EXISTS (
        SELECT 1
        FROM tb_zones zz, tb_zones zz2
        WHERE zz2.parent_zone_id = z3.zone_id
        AND zz.parent_zone_id = zz2.zone_id
        AND zz2.zone_id != z2.zone_id
        AND zz.name = z.name
    )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zones zz, tb_zones zz2
        WHERE zz2.parent_zone_id = z3.zone_id
        AND zz.parent_zone_id = zz2.zone_id
        AND zz2.zone_id != z2.zone_id
        AND zz.name = z.name
        AND NVL(zz.default_flag, 'N') = 'Y'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_95 finished.',runId);
    COMMIT;
END;


 
 
 
/