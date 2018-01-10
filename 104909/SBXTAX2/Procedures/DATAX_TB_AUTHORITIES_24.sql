CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_24
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="24" name="Mapped Authorities with no Logic Mapping" >
   dataCheckId NUMBER := -673;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_24 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authority_logic_group_xref x
        WHERE x.authority_id = a.authority_id
        )
    AND EXISTS (
        SELECT 1
        FROM tb_zone_authorities z
        WHERE z.authority_id = a.authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_24 finished.',runId);
    COMMIT;
END;
 
 
/