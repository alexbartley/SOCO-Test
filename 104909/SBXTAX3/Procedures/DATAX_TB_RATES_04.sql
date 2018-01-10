CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rates_04
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="04" name="Rates with no Authority" >
   dataCheckId NUMBER := -750;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_04 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_authorities ra
        WHERE ra.authority_id = r.authority_id
        AND ra.merchant_id = r.merchant_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_04 finished.',runId);
    COMMIT;
END;
 
 
/