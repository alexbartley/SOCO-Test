CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_146
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="146" name="No Default for City Zones in multiple Provinces">
   dataCheckId NUMBER := -733;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_146 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT zone_id, dataCheckId, runId, SYSDATE
    FROM (
        SELECT z.zone_id, COUNT(*) OVER (PARTITION BY z.name,
            CASE WHEN parent.name = 'BC' THEN 'BRITISH COLUMBIA'
            WHEN parent.name = 'AB' THEN 'ALBERTA'
            WHEN parent.name = 'MB' THEN 'MANITOBA'
            WHEN parent.name = 'NB' THEN 'NEW BRUNSWICK'
            when parent.name = 'NF' THEN 'NEWFOUNDLAND'
            WHEN parent.name = 'NL' THEN 'LABRADOR'
            WHEN parent.name = 'NT' THEN 'NORTHWEST TERRITORIES'
            WHEN parent.name = 'NS' THEN 'NOVA SCOTIA'
            WHEN parent.name = 'NU' THEN 'NUNAVAT'
            WHEN parent.name = 'ON' THEN 'ONTARIO'
            WHEN parent.name = 'PE' THEN 'PRINCE EDWARD ISLAND'
            WHEN parent.name = 'PQ' THEN 'QUEBEC'
            WHEN parent.name = 'QC' THEN 'QUEBEC'
            WHEN parent.name = 'SK' THEN 'SASKATCHEWAN'
            WHEN parent.name = 'YT' THEN 'YUKON'
            ELSE parent.name END) total
        FROM tb_zones z, tb_zones parent, tb_zone_levels zl, (
            SELECT z.merchant_id, z.name
            FROM tb_zones z, tb_zone_levels zl
            WHERE z.zone_level_id = zl.zone_level_id
            AND z.merchant_id = taxDataProviderId
            AND zl.name = 'City'
            AND NOT EXISTS (
                SELECT 1
                FROM tb_zones z2
                WHERE z2.zone_level_id = z.zone_level_id
                AND NVL(z2.default_flag,'N') = 'Y'
                AND z2.name = z.name
            )
            GROUP BY z.merchant_id, z.name
            HAVING COUNT(*) > 1
        ) multis
        WHERE z.zone_level_id = zl.zone_level_id
        AND -1 > parent.zone_level_id
        AND zl.name = 'City'
        AND multis.name = z.name
        AND multis.merchant_id = z.merchant_id
        AND parent.zone_id = z.parent_zone_id
    )
    --GROUP BY name, parent
    --HAVING COUNT(*) = 1
    WHERE total = 1
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_146 finished.',runId);
    COMMIT;
END;
 
 
/