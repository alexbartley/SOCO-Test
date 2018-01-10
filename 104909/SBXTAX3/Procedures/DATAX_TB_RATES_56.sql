CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_rates_56
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "56" name="Rate Descriptions with Trailing Spaces" >
   dataCheckId NUMBER := -772;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_56 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM  tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND (r.description LIKE '% ' OR r.description LIKE ' %' OR r.description LIKE '%  %')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_56 finished.',runId);
    COMMIT;
END;
 
 
/