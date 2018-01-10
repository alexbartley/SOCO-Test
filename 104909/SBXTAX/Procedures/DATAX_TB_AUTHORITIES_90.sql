CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_AUTHORITIES_90"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="90" name="Rental Authorities without active Standard Rates" >
   dataCheckId NUMBER := -687;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_90 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.name LIKE '%RENTAL%'
    AND (
        NOT EXISTS (
            SELECT 1 FROM tb_rates r
            WHERE r.rate_code = 'RS'
            AND r.merchant_id = a.merchant_id
            AND r.authority_id = a.authority_id
            AND r.end_date IS NULL
        )
        OR NOT EXISTS (
            SELECT 1
            FROM tb_rates r
            WHERE r.rate_code = 'RU'
            AND r.merchant_id = a.merchant_id
            AND r.authority_id = a.authority_id
            AND r.end_date IS NULL
        )
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_90 finished.',runId);
    COMMIT;
END;


 
 
/