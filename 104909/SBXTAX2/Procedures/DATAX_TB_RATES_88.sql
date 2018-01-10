CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rates_88
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="88" name="Rate Tier's Rate that doesn't match its Rate Code's Rate" >
   dataCheckId NUMBER := -691;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_88 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r, tb_rate_tiers rt
    WHERE r.merchant_id = taxDataProviderId
    AND rt.rate_id = r.rate_id
    AND rt.rate_code IS NOT NULL
    AND r.rate_code NOT LIKE ('%' || rt.rate_code)
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_88 finished.',runId);
    COMMIT;
END;
 
 
/