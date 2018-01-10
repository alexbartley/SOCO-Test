CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rates_78
   ( taxDataProviderId IN NUMBER,  runId IN OUT NUMBER)
   IS
   --<data_check id="78" name="Duplicate Rates" >
   dataCheckId NUMBER := -747;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_78 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND EXISTS (
        SELECT 1
        FROM tb_rates r2
        WHERE r2.rate_code = r.rate_code
        AND r2.authority_id = r.authority_id
        AND r2.start_date = r.start_date
        AND nvl(r2.is_local, 'N') = nvl(r.is_local, 'N')
        AND r.rate_id > r2.rate_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_78 finished.',runId);
    COMMIT;
END;
 
 
/