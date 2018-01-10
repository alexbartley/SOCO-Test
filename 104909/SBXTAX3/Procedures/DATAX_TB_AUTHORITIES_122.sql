CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_122
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
    --<data_check id="122" name="ICMS Authorities with incorrect Authority Type" >
    dataCheckId NUMBER := -683;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_122 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_authority_types t
    WHERE a.merchant_id = taxDataProviderId
    AND a.name like '%ICMS%'
    AND a.authority_type_id = t.authority_type_id
    AND t.name != 'ICMS'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_122 finished.',runId);
    COMMIT;
END;
 
 
/