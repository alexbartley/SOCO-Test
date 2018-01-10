CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RATES_96"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="96" name="Texas rates with Wrong Tier Type" >
   dataCheckId NUMBER := -658;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_96 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rates r
    WHERE r.merchant_id = taxDataProviderId
    AND r.authority_id = a.authority_id
    AND a.name LIKE 'TX%'
    AND a.name NOT LIKE 'TX - STATE%'
    AND NVL(r.split_type,'X') != 'T'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_96 finished.',runId);
    COMMIT;
END;


 
 
 
/