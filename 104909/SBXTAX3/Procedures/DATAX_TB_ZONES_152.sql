CREATE OR REPLACE PROCEDURE sbxtax3.DATAX_TB_ZONES_152
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="152" name="Zones with multiple authorities where one authority is No Content or No VAT OR no PST">
   dataCheckId NUMBER := -693;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_152 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT za.zone_Authority_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z, tb_authorities a, tb_zone_authorities za
    WHERE a.merchant_id = taxDataProviderId
    AND a.authority_id = za.authority_id
    AND z.zone_id = za.zone_id
    AND z.zone_id in (
        SELECT z2.zone_id
        FROM tb_zone_authorities z2, tb_authorities a2
        WHERE a2.authority_id = z2.authority_id
        AND a2.merchant_id = taxDataProviderId
        GROUP BY z2.zone_id
        HAVING COUNT(*)>1
    )
    AND a.name IN ('No Content', 'No VAT','No PST')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.zone_authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_152 finished.',runId);
    COMMIT;
END;
 
 
/