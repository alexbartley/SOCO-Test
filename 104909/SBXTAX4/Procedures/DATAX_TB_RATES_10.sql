CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RATES_10"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="10" name="Overlapping Rates" >
   dataCheckId NUMBER := -628;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_10 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND r.end_date IS NULL
    AND EXISTS (
        SELECT 1
        FROM tb_rates r2
        WHERE r2.rate_code = r.rate_code
        AND r2.start_date > r.start_date
        AND r.authority_id = r2.authority_id
        AND nvl(r.is_local, 'N') = nvl(r2.is_local, 'N')
    )

    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_10 finished.',runId);
    COMMIT;
END;


 
 
 
/