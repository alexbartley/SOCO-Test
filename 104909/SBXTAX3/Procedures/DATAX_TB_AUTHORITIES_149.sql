CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_149
   ( taxDataProviderId IN VARCHAR2, runId IN OUT NUMBER)
   IS
   --<data_check id="149" name="Missing authority Logic Mappings">
   dataCheckId NUMBER := -624;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_149 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    from tb_authorities a
    where a.merchant_id = taxDataProviderId
    and not exists (
        select 1
        from tb_authority_logic_group_xref x
        where a.authority_id = x.authority_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        AND reviewed_Approved IS NOT NULL
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_149 finished.',runId);
    COMMIT;
END;
 
 
/