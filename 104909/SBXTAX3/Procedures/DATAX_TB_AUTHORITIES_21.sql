CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_21
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="21" name="County Authorities not Mapped at County Zone Level" >
   dataCheckId NUMBER := -734;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_21 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_authority_types aty, tb_zone_levels zl
    WHERE a.merchant_id = taxDataProviderId
    AND aty.name in ('County Sales/Use', 'County Rental')
    AND a.effective_zone_level_id != -5
    AND a.authority_type_id = aty.authority_type_id
    AND a.effective_zone_level_id = zl.zone_level_id
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_21 finished.',runId);
    COMMIT;
END;
 
 
/