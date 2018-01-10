CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_162
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="162" name="Lowest Mapped level has changed (needs to be reported to MTS team)">
   dataCheckId NUMBER := -692;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_162 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_misc_output (primary_key, table_name, data_check_id, run_id, creation_date) (
    SELECT current_lowest_level.lowest_mapped_level, current_lowest_level.zone_3_name, dataCheckId, runId, SYSDATE
    FROM (
        SELECT zone_3_name, MIN(
            CASE WHEN zone_4_id IS NULL THEN 5
            WHEN zone_5_id IS NULL THEN 4
            WHEN zone_6_id IS NULL THEN 3
            WHEN zone_7_id IS NULL THEN 2
            ELSE 1 END
            ) lowest_mapped_level
        FROM ct_zone_authorities z
        JOIN tb_authorities a ON (a.name = z.authority_name)
        LEFT OUTER JOIN tb_rates r ON (r.authority_id = a.authority_id AND r.merchant_id = a.merchant_id AND r.end_Date IS NULL AND NVL(r.rate,1) > 0)
        WHERE zone_3_name IS NOT NULL
        GROUP BY zone_3_name
    ) current_lowest_level
    LEFT OUTER JOIN ct_zone_auth_level_by_state zal ON (zal.zone_3_name = current_lowest_level.zone_3_name)
    WHERE zal.lowest_mapped_level != NVL(current_lowest_level.lowest_mapped_level,0)
    AND (
        (5 > NVL(current_lowest_level.lowest_mapped_level,0) AND NVL(zal.lowest_mapped_level,0) = 5)
        OR
        (5 > NVL(zal.lowest_mapped_level,0) AND NVL(current_lowest_level.lowest_mapped_level,0) = 5)
    )
    );


    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_162 finished.',runId);
    COMMIT;
END;
 
 
/