CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_rules_91
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="91" name="Rule End Periods not matching Rate End Periods" >
   dataCheckId NUMBER := -684;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_91 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND r.authority_id = a.authority_id
    AND r.rate_code IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates u
        WHERE u.authority_id = a.authority_id
        AND u.rate_code = r.rate_code
        AND nvl(u.end_date, to_date('9999.01.01', 'YYYY.MM.DD')) >= nvl(r.end_date, to_date('9999.01.01','YYYY.MM.DD')))
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates ra2, tb_authorities a2
        where a2.merchant_id = r.merchant_id
        AND a2.name like (substr(a.name, 0, 2) || '%STATE%')
        AND ra2.authority_id = a2.authority_id
        AND ra2.is_local = 'Y'
        AND nvl(ra2.end_date, to_date('9999.01.01', 'YYYY.MM.DD')) >= nvl(r.end_date, to_date('9999.01.01','YYYY.MM.DD'))
        AND ra2.rate_code = r.rate_code
    )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key =  r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_91 finished.',runId);
    COMMIT;
END;
 
 
/