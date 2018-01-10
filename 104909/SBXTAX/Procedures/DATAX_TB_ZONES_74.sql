CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_74"
   (runId IN OUT NUMBER)
   IS
   --<data_check id="74" name="Non Short List Zones without Tax Parent Zone" >
   dataCheckId NUMBER := -758;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_74 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z, tb_zone_levels l, tb_merchants m
    WHERE z.merchant_id = m.merchant_id
    AND m.name LIKE 'Sabrix%Tax Data'
    AND z.zone_level_id = l.zone_level_id
    AND l.display_in_short_list = 'N'
    AND z.tax_parent_zone_id IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_74 finished.',runId);
    COMMIT;
END;


 
 
/