CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_70
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="70" name="Duplicate Zones" >
   dataCheckId NUMBER := -627;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_70 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z1.primary_key, dataCheckId, runId, SYSDATE
    FROM (
        SELECT zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
        FROM ct_zone_tree
        WHERE merchant_id = taxDataProviderId
        GROUP BY zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
        HAVING COUNT(*) > 1

    ) dupes, ct_zone_Tree z1
    WHERE NVL(dupes.zone_1_name,'ZONE_1_NAME') = NVL(z1.zone_1_name,'ZONE_1_NAME')
    AND NVL(dupes.zone_2_name,'ZONE_2_NAME') = NVL(z1.zone_2_name,'ZONE_2_NAME')
    AND NVL(dupes.zone_3_name,'ZONE_3_NAME') = NVL(z1.zone_3_name,'ZONE_3_NAME')
    AND NVL(dupes.zone_4_name,'ZONE_4_NAME') = NVL(z1.zone_4_name,'ZONE_4_NAME')
    AND NVL(dupes.zone_5_name,'ZONE_5_NAME') = NVL(z1.zone_5_name,'ZONE_5_NAME')
    AND NVL(dupes.zone_6_name,'ZONE_6_NAME') = NVL(z1.zone_6_name,'ZONE_6_NAME')
    AND NVL(dupes.zone_7_name,'ZONE_7_NAME') = NVL(z1.zone_7_name,'ZONE_7_NAME')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z1.primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_70 finished.',runId);
    COMMIT;
END;
 
 
/