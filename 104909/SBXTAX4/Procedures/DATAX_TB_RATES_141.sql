CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RATES_141"
   ( taxDataProviderId IN NUMBER,runId IN OUT NUMBER)
   IS
   --<data_check id="141" name="Non-Basic Rates with mismatched Tier Amounts">
   dataCheckId NUMBER := -680;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_141 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ro.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_rates ro
    WHERE ro.merchant_id = taxDataProviderId
    AND ro.split_type IS NOT NULL
    AND nvl(ro.end_date,'31-dec-9999') > sysdate
    AND EXISTS (
        SELECT ra.authority_id, ra.is_local, CASE WHEN LENGTH(ra.rate_code) = 2 THEN 'X'
        ELSE SUBSTR(ra.rate_code,1,LENGTH(ra.rate_code)-2) END rate_group,
        COUNT(DISTINCT NVL(ra.split_amount_type,'XX') ) number_of_types
        FROM tb_rates ra
        WHERE ra.merchant_id = ro.merchant_id
        AND ra.authority_id = ro.authority_id
        AND (ra.rate_code LIKE '%CU' OR ra.rate_code LIKE '%ST' OR ra.rate_code LIKE '%SU')
        AND nvl(ra.end_date,'31-dec-9999') > sysdate
        AND ra.split_type IS NOT NULL
        GROUP BY ra.authority_id, ra.is_local, CASE WHEN LENGTH(ra.rate_code) = 2 THEN 'X'
        ELSE SUBSTR(ra.rate_code,1,LENGTH(ra.rate_code)-2) END
        HAVING COUNT(DISTINCT NVL(ra.split_amount_type,'XX') ) > 1
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ro.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_141 finished.',runId);
    COMMIT;
END;


 
 
 
/