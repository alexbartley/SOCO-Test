CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_154"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="154" name="Duplicate 3 Char Codes">
   dataCheckId NUMBER := -635;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_154 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.merchant_id = taxDataProviderId
    AND EXISTS(
        SELECT 1
        FROM tb_zones z2, tb_zones pz2, tb_zones pz
        WHERE pz2.zone_id = z2.parent_zone_id
        AND pz.zone_id = z.parent_zone_id
        AND pz.name = pz2.name
        AND pz.merchant_id = pz2.merchant_id
        AND z.merchant_id = z2.merchant_id
        AND z.code_3char = z2.code_3char
        AND z.zone_id != z2.zone_id
        AND z.name != z2.name
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_154 finished.',runId);
    COMMIT;
END;


 
 
/