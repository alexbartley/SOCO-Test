CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_zones_14
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="14" name="Zones with Excessive Spaces" >
   dataCheckId NUMBER := -645;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_14 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.merchant_id = taxDataProviderId
    AND (z.name LIKE '% ' OR z.name LIKE ' %' OR z.name LIKE '%  %')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_14 finished.',runId);
    COMMIT;
END;
 
 
/