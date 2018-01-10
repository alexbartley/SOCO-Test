CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONES_170"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -792;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_170 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT z.primary_key, dataCheckId, runId, SYSDATE
    from ct_zone_tree z
    WHERE z.ZONE_7_NAME IS NOT NULL
	AND  NVL(SUBSTR(z.CODE_FIPS, 16),-1234) != ZONE_7_NAME -- NVL added to fix 2049
    AND z.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_170 finished.',runId);
    COMMIT;
END;
 
/