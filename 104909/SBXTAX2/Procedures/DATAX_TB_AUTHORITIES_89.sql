CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_89
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="89" name="Authorities without active Standard Rates" >
   dataCheckId NUMBER := -728;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_89 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    from tb_authorities a
    where a.merchant_id = taxDataProviderId
    AND (
        NOT EXISTS (
            SELECT 1
            FROM tb_rates r
            WHERE r.rate_code = 'ST'
            AND r.merchant_id = a.merchant_id
            AND r.authority_id = a.authority_id
            AND r.end_date IS NULL
            )
        OR NOT EXISTS (
            SELECT 1
            FROM tb_rates r
            where r.rate_code = 'SU'
            AND r.merchant_id = a.merchant_id
            AND r.authority_id = a.authority_id
            AND r.end_date IS NULL
            )
        OR NOT EXISTS (
            SELECT 1
            FROM tb_rates r
            WHERE r.rate_code = 'CU'
            AND r.merchant_id = a.merchant_id
            AND r.authority_id = a.authority_id
            AND r.end_date IS NULL
            )
    )
    AND a.name NOT LIKE 'US - %'
    AND a.name NOT LIKE '%Template%'
    AND a.name NOT LIKE '%RENTAL%'
    AND a.name != 'TN - STATE EXTENDED CAP'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_89 finished.',runId);
    COMMIT;
END;
 
 
/