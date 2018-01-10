CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONES_64"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "64" name="Zips with multiple defaults within a State" >
   dataCheckId NUMBER := -764;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_64 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT zone_id, dataCheckId, runId, SYSDATE
    FROM (
        select z.primary_key zone_id, COUNT(*) OVER (PARTITION BY z.zone_3_name, z.zone_6_name) total
        from ct_zone_tree z
        where z.zone_6_level_id = -7
        AND z.merchant_id = taxDataProviderId
        AND z.default_flag = 'Y'
        AND z.zone_7_id IS NULL
    )
    WHERE total > 1
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_64 finished.',runId);
    COMMIT;
END;


 
 
 
/