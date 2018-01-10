CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_161"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="161" name="WA incorrect authority mapping">
   dataCheckId NUMBER := -651;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_161 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT authority_id, dataCheckId, runId, SYSDATE
    FROM (
        SELECT zone_4_name, zone_5_name, zone_6_name, zone_7_name, a.authority_id,
            CASE WHEN zone_5_name IS NULL THEN -5
                WHEN zone_6_name IS NULL THEN -6
                ELSE -7 END mapped_level,
            a.effective_zone_level_id,
            LAG(effective_zone_level_id) OVER (PARTITION BY zone_4_name, zone_5_name,zone_6_name ORDER BY  zone_4_name, zone_5_name, zone_6_name) prev_level
        FROM ct_zone_authorities za, tb_authorities a, tb_zones z
        WHERE zone_3_name = 'WASHINGTON'
        AND a.merchant_id = taxDataProviderId
        AND a.merchant_id = z.merchant_id
        AND zone_4_name is not null
        AND a.name = za.authority_name
        AND a.name LIKE 'WA%'
        AND a.name NOT LIKE '%(RTA)%'
        AND z.zone_id = za.primary_key
        AND z.reverse_flag = 'N'
    )
    WHERE prev_level IS NOT NULL
    AND effective_zone_level_id > prev_level
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_161 finished.',runId);
    COMMIT;
END;


 
 
 
/