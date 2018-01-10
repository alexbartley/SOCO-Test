CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rates_23
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="23" name="Tiered Rates with no Tiers" >
   dataCheckId NUMBER := -643;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_23 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND NVL(r.split_type,'X') in ('R','G')
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rate_tiers rt
        WHERE rt.rate_id = r.rate_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_23 finished.',runId);
    COMMIT;
END;
 
 
/