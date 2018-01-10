CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_52"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "52" name="Tax Holiday Rules with Mismatched Rate Dates" >
   dataCheckId NUMBER := -776;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_52 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ru.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules ru
    WHERE ru.merchant_id =taxDataProviderId
    AND a.authority_id = ru.authority_id
    AND ru.rate_code like 'TH%'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates r
        WHERE r.rate_code = ru.rate_code
        and r.authority_id = ru.authority_id
        AND r.start_date = ru.start_date
        AND r.end_date = ru.end_date
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ru.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_52 finished.',runId);
    COMMIT;
END;
 
/