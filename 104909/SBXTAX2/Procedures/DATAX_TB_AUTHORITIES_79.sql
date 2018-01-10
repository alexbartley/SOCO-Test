CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_79
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="79" name="Duplicate Logic XRef" >
   dataCheckId NUMBER := -748;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_79 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_authority_logic_groups  g, tb_authority_logic_group_xref  x, tb_authority_logic_group_xref  x2,
        tb_authority_logic_groups  g2
    WHERE a.merchant_id = taxDataProviderId
    AND a.authority_id = x.authority_id
    AND x.authority_id = x2.authority_id
    AND g.authority_logic_group_id = x.authority_logic_group_id
    AND g2.authority_logic_group_id = x2.authority_logic_group_id
    AND x2.process_order = x.process_order
    AND x.end_date IS NULL
    AND nvl(x2.end_date, to_date('2900.01.01', 'YYYY.MM.DD')) > x.start_date
    AND x.authority_logic_group_xref_id > x2.authority_logic_group_xref_id
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_79 finished.',runId);
    COMMIT;
END;
 
 
/