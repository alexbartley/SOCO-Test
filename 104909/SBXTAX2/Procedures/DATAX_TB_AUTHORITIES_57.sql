CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_57
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "57" name="Rental Authority Type mismatches" >
   dataCheckId NUMBER := -771;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_57 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_authority_types ay
    WHERE a.merchant_id = taxDataProviderId
    AND a.authority_type_id = ay.authority_type_id
    AND (
        (a.name NOT LIKE '%RENTAL%' AND ay.name LIKE '%Rental') OR
        (a.name LIKE '%RENTAL%' AND ay.name NOT LIKE '%Rental')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_57 finished.',runId);
    COMMIT;
END;
 
 
/