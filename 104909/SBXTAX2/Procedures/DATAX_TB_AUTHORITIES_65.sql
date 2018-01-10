CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_65
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "65" name="AL Non-rental Authorities without MM rates" >
   dataCheckId NUMBER := -763;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_65 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.name LIKE 'AL%'
    AND a.name NOT LIKE '%RENTAL%'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates r
        WHERE r.authority_id = a.authority_id
        AND r.merchant_id = a.merchant_id
        AND r.rate_code LIKE 'MM%'
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_65 finished.',runId);
    COMMIT;
END;
 
 
/