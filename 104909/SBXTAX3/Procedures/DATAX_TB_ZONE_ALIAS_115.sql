CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zone_alias_115
   ( taxDataProviderId IN NUMBER,  runId IN OUT NUMBER)
   IS
   --<data_check id="115" name="Full Match Zone Aliases with no matching Zone" >
   dataCheckId NUMBER := -731;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_ALIAS_115 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT zmp.zone_match_pattern_id, dataCheckId, runId, SYSDATE
    FROM  tb_zone_match_patterns zmp
    WHERE zmp.merchant_id = taxDataProviderId
    AND zmp.type = 'FL'
    AND EXISTS (
        SELECT 1
        FROM tb_zone_match_contexts zmc
        WHERE zmc.zone_match_pattern_id = zmp.zone_match_pattern_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_zones z
        WHERE z.name = zmp.value
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = zmp.zone_match_pattern_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_ALIAS_115 finished.',runId);
    COMMIT;
END;
 
 
/