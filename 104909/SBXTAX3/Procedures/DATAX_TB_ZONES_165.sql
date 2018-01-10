CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_165
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
    --<data_check id="165" name="Zones not in CT_COUNTRY_CURRENCIES" >
    dataCheckId NUMBER := -786;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_165 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.merchant_id = taxDataProviderId
    AND z.zone_level_id = -1 --Must have Zone Level of Country
    AND NOT EXISTS (
        SELECT 1 --Check for existence in CT_COUNTRY_CURRENCIES
        FROM ct_country_currencies cc
        WHERE cc.sabrix_country_zone = z.name
        )
    AND NOT EXISTS (
        SELECT 1 --exclude Zones that are "duplicated" as Country and Province/State
        FROM tb_zones z2
        WHERE z2.name = z.name
        AND z2.zone_level_id in (-2,-4)
        )
    AND EXISTS (
        SELECT 1 --exclude Zones that only have a "No" Authority
        FROM tb_zone_authorities za, tb_authorities a
        WHERE z.zone_id = za.zone_id
        AND a.authority_id = za.authority_id
        and a.name not IN ('No VAT','No Content','No PST')
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_165 finished.',runId);
    COMMIT;
END;
/