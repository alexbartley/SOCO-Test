CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rates_99
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
    --<data_check id="99" name="Check for Date Gaps" >
    dataCheckId NUMBER := -704;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_99 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT rate_id, dataCheckId, runId, SYSDATE
    FROM (
        SELECT rate_id, end_date, LEAD(START_DATE) OVER (PARTITION BY authority_id,rate_code, NVL(is_local,'N') ORDER BY authority_id, rate_code, start_date) next_start_date
        FROM tb_rates r1
        WHERE r1.merchant_id = taxDataProviderId
        AND rate_code NOT LIKE 'TH%'
    )
    WHERE end_date IS NOT NULL
    AND end_date+1 != next_start_date
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_99 finished.',runId);
    COMMIT;
END;
 
 
/