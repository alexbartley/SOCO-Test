CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RATES_05"
   ( runId IN OUT NUMBER)
   IS
   --<data_check id="05" name="Rates with Null Code" >
   dataCheckId NUMBER := -749;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_05 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r
    WHERE r.rate_code IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_05 finished.',runId);
    COMMIT;
END;


 
 
/