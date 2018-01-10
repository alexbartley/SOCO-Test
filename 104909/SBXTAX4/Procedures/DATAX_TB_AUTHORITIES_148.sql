CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_148"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="148" name="AR - STATE rules not in TEXARKANA">
   dataCheckId NUMBER := -659;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_148 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
   SELECT distinct r.rule_id, dataCheckId, runId, SYSDATE  -- a.authority_id replaced with r.rule_id for CRAPP-2193
    FROM tb_authorities a, tb_rules  r
    WHERE a.name LIKE 'AR - STATE SALES/USE TAX'
    AND r.authority_id = a.authority_id
    AND r.merchant_id = a.merchant_id
    AND r.end_date IS NULL
    AND a.merchant_id = taxDataProviderId
    AND NVL(r.is_local, 'N') = 'Y'
    AND NOT EXISTS (
        SELECT r2.RULE_ORDER
        FROM tb_authorities  a2, tb_rules  r2
        WHERE a2.name LIKE 'AR - STATE ADDITIONAL TEXARKANA SALES/USE TAX'
        AND a2.authority_id = r2.authority_id
        AND r2.merchant_id = r.merchant_id
        AND nvl(r2.is_local, 'N') = 'Y'
        AND r2.rule_order = r.rule_order
        AND r2.start_date = r.start_date
        AND r2.end_date IS NULL
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_148 finished.',runId);
    COMMIT;
END;
 
/