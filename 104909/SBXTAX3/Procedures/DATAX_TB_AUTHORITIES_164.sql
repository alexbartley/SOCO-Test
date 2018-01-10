CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_164
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="164" name="Authority with Effective Zone Level not at District, City, County, or State">
   dataCheckId NUMBER := -634;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_164 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_zone_levels z
    WHERE a.effective_zone_level_id = z.zone_level_id
    AND a.merchant_id = taxDataProviderId
    AND z.name NOT IN ('District','City','County','State')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_164 finished.',runId);
    COMMIT;
END;
 
 
/