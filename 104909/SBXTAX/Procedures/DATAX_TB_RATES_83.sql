CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RATES_83"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="83" name="SU, CU, and ST Rates that don't have the same Rate" >
   dataCheckId NUMBER := -735;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_83 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r1.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r1, tb_rates r2, tb_rates r3
    WHERE r1.merchant_id = taxDataProviderId
    AND r2.merchant_id = r3.merchant_id
    AND r1.merchant_id = r2.merchant_id
    AND r1.authority_id = r2.authority_id
    AND r2.authority_id = r3.authority_id
    AND r1.rate_code = 'SU'
    AND r2.rate_code = 'CU'
    AND r3.rate_code = 'ST'
    AND r1.rate != 0
    AND r2.rate != 0
    AND r1.start_date = r2.start_date
    AND r1.start_date >= r3.start_date
    AND r1.end_date IS NULL
    AND r3.end_date IS NULL
    AND r2.end_date IS NULL
    AND (r1.rate != r2.rate or r2.rate != r3.rate)
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r1.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_83 finished.',runId);
    COMMIT;
END;


 
 
/