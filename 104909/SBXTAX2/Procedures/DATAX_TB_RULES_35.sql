CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_35
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="35" name="State Level Standard Rules without correct (Standard Rule Order + 1) Cascading Rule" >
   dataCheckId NUMBER := -744;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_35 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules r, tb_authorities a
    WHERE r.merchant_id = taxDataProviderId
    AND a.merchant_id = r.merchant_id
    AND (a.name like '%- STATE%' or a.name = 'DC - DISTRICT SALES/USE TAX')
    AND a.name != 'TN - STATE EXTENDED CAP'
    AND a.name not like '%RENTAL%'
    AND a.authority_id = r.authority_id
    AND r.rule_order in (9970, 9980, 9990, 8970, 8980, 8990)
    AND (r.is_local is null or r.is_local = 'N')
    AND not exists (
        select 1
        from tb_rules r2
        where r2.authority_id = r.authority_id
        AND r2.start_date = r.start_date
        AND r2.rule_order = r.rule_order + 1
        AND r2.rate_code = r.rate_code
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_35 finished.',runId);
    COMMIT;
END;
 
 
/