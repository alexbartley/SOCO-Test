CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RATES_42"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="42" name="Invalid Rate Codes" >
   dataCheckId NUMBER := -702;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_42 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rate_id, dataCheckId, runId, SYSDATE
	FROM tb_rates r
	LEFT OUTER JOIN ct_rate_prefix_lookup l ON (r.rate_code LIKE l.rate_prefix||'%')
	WHERE r.merchant_id = taxDataProviderId
	AND r.rate_code NOT IN ('ST','CU','SU')
	AND l.rate_prefix IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_42 finished.',runId);
    COMMIT;
END;


 
 
/