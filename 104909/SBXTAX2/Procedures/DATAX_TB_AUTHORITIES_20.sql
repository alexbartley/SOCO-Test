CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_20
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="20" name="City Authorities not Mapped at City Zone Level" >
   dataCheckId NUMBER := -682;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_20 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_authority_types aty, tb_zone_levels zl
    WHERE a.merchant_id = taxDataProviderId
    AND aty.name in ('City Sales/Use', 'City Rental')
    AND a.effective_zone_level_id != -6
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
    VALUES ('DATAX_TB_AUTHORITIES_20 finished.',runId);
    COMMIT;
END;
 
 
/