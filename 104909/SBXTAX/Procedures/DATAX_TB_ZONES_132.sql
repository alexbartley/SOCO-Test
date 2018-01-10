CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_132"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="132" name="EU As of Date is Null">
   dataCheckId NUMBER := -633;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_132 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.parent_zone_id = (
        SELECT z2.zone_id
        FROM tb_zones z2
        WHERE z2.merchant_id = z.merchant_id
        AND z2.name = 'EUROPEAN UNION'
        )
    AND z.eu_zone_as_of_date IS NULL
    AND z.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_132 finished.',runId);
    COMMIT;
END;


 
 
/