CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_107
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="107" name="Authority Logic Mappings with same Start Date and Process Order" >
   dataCheckId NUMBER := -760;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_107 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a,
    tb_authority_logic_groups alg1,
    tb_authority_logic_groups alg2,
    tb_authority_logic_group_xref algx1,
    tb_authority_logic_group_xref algx2
    WHERE a.merchant_id = taxDataProviderId
    AND a.authority_id = algx1.authority_id
    AND a.authority_id = algx2.authority_id
    AND algx1.authority_logic_group_xref_id != algx2.authority_logic_group_xref_id
    AND algx1.authority_logic_group_id = alg1.authority_logic_group_id
    AND algx2.authority_logic_group_id = alg2.authority_logic_group_id
    AND algx1.start_date = algx2.start_date
    AND algx1.process_order = algx2.process_order
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_107 finished.',runId);
    COMMIT;
END;
 
 
/