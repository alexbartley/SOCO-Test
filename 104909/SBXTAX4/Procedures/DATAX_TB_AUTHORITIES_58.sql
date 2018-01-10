CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_58"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "58" name="Authorities without a 1-1-2000 or earlier JD Mapping" >
   dataCheckId NUMBER := -770;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_58 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND NVL(a.is_template, 'N') != 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authority_logic_group_xref x
        WHERE TO_DATE('2000.01.01', 'YYYY.MM.DD') >= x.start_date
        AND x.authority_id = a.authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_58 finished.',runId);
    COMMIT;
END;


 
 
 
/