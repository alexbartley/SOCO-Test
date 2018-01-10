CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_28"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="28" name="Mismatched Rate Codes and Tax Types" >
   dataCheckId NUMBER := -722;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_28 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE r.authority_id = a.authority_id
    AND r.merchant_id = taxDataProviderId
    AND a.name != 'US - NO TAX STATES'
    AND a.merchant_id = r.merchant_id
    AND r.rate_code in ('CU', 'MMCU', 'MMSU', 'NL', 'RU', 'SU', 'ST', 'RS', 'MMST')
    AND r.rate_code || ', ' || r.tax_type NOT IN ('CU, CU', 'MMCU, CU', 'MMSU, US', 'NL, NL', 'RU, RU', 'SU, US','ST, ', 'RS, ', 'MMST, ')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_28 finished.',runId);
    COMMIT;
END;


 
 
 
/