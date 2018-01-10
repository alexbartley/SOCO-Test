CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RATE_TIERS_85"
   (runId IN OUT NUMBER)
   IS
   --<data_check id="85" name="Orphaned Rate Tiers" >
   dataCheckId NUMBER := -623;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATE_TIERS_85 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT t.rate_tier_id, dataCheckId, runId, SYSDATE
    FROM tb_rate_tiers t
    WHERE NOT EXISTS(
        SELECT 1
        FROM tb_rates r
        WHERE r.rate_id = t.rate_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = t.rate_tier_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATE_TIERS_85 finished.',runId);
    COMMIT;
END;


 
 
 
/