CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_zones_134
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="134" name="Duplicate Country 2 Char Codes">
   dataCheckId NUMBER := -649;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_134 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z, tb_zone_levels zl
    WHERE code_2char IS NOT NULL
    AND z.zone_level_id = zl.zone_level_id
    AND zl.name = 'Country'
    AND NVL(code_2char,'xx') IN (
        SELECT NVL(z.code_2char,'xx') code_2char
        FROM tb_zones z
        WHERE z.zone_level_id = zl.zone_level_id
        AND z.merchant_id = taxDataProviderId
        GROUP BY NVL(z.code_2char,'xx')
        HAVING COUNT(*) > 1
    )

    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_134 finished.',runId);
    COMMIT;
END;
 
 
/