CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ALGX_33"
   (runId IN OUT NUMBER)
   IS
   --<data_check id="33" name="ALGX record orphaned by Authority" >
   dataCheckId NUMBER := -755;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ALGX_33 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ax.authority_logic_group_xref_id, dataCheckId, runId, SYSDATE
    from tb_authority_logic_group_xref ax, tb_authority_logic_groups g
    where g.authority_logic_group_id = ax.authority_logic_group_id
    and not exists (
        select 1
        from tb_authorities a
        where a.authority_id = ax.authority_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ax.authority_logic_group_xref_id
        AND data_check_id = dataCheckId
        )
    );
    COMMIT;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ALGX_33 finished.',runId);
    COMMIT;
END;


 
 
 
/