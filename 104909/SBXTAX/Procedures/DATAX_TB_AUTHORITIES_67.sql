CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_AUTHORITIES_67"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "67" name="CO County Non-matching ST and SU Rates" >
   dataCheckId NUMBER := -761;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_67 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rates st, tb_rates su
    WHERE a.merchant_id = taxDataProviderId
    AND st.authority_id = a.authority_id
    AND su.authority_id = a.authority_id
    AND st.rate_code = 'ST'
    AND su.rate_code = 'SU'
    AND a.name LIKE 'CO%COUNTY%'
    AND st.end_date IS NULL
    AND su.end_date IS NULL
    AND st.rate != su.rate
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_67 finished.',runId);
    COMMIT;
END;


 
 
/