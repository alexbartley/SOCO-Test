CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_zones_80
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="80" name="Reservation Zones" >
   dataCheckId NUMBER := -630;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_80 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z, tb_authorities  a, tb_zone_authorities  za
    WHERE z.merchant_id = taxDataProviderId
    AND a.name in (
        'UT - NAVAJO NATION, TRIBAL SALES TAX',
        'SD - PINE RIDGE TRIBAL TAX, DISTRICT SALES/USE TAX',
        'NM - NAVAJO NATION, TRIBAL SALES TAX',
        'SC - CATAWBA TRIBAL SALES/USE TAX'
    )
    AND za.authority_id = a.authority_id
    AND z.zone_level_id IN (-8,-7)
    AND z.zone_id = za.zone_id
    AND (NVL(z.reverse_flag, 'N') = 'N' OR NVL(z.terminator_flag, 'N') = 'N')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_80 finished.',runId);
    COMMIT;
END;
 
 
/