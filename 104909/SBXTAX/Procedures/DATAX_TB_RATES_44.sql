CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RATES_44"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="44" name="Rates without 1-1-2000 Instances" >
   dataCheckId NUMBER := -655;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_44 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND r.authority_id = a.authority_id
    AND (r.rate_code in ('CU', 'NL', 'ST', 'SU', 'RS', 'RU') OR (rate_code IN ('MMCU', 'MMST', 'MMSU') AND a.name LIKE 'AL%'))
    AND NOT EXISTS(
        SELECT 1
        FROM tb_rates
        WHERE rate_code = r.rate_code
        AND authority_id = r.authority_id
        AND start_date = to_date('2000.01.01', 'YYYY.MM.DD')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_44 finished.',runId);
    COMMIT;
END;


 
 
/