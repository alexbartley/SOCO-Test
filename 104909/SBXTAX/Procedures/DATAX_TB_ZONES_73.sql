CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_73"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="73" name="Short List Zones with Tax Parent Zones" >
   dataCheckId NUMBER := -757;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_73 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z, tb_zone_levels l
    WHERE z.merchant_id = taxDataProviderId
    AND z.zone_level_id = l.zone_level_id
    AND l.display_in_short_list = 'Y'
    AND z.tax_parent_zone_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_73 finished.',runId);
    COMMIT;
END;


 
 
/