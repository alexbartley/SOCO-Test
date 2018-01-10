CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_RULES_150"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="150" name="Mismatched PT in AK Authorities">
   dataCheckId NUMBER := -714;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_150 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT outerr.rule_id, dataCheckId, runId, SYSDATE
    from tb_authorities outera, tb_rules outerr, (
        select r.rule_order, r.start_Date, r.product_category_id, r.rate_Code, r.exempt , r.tax_type, r.is_local
        from tb_rules r, tb_authorities a
        where r.authority_id = a.authority_id
        and a.merchant_id = r.merchant_id
        and r.merchant_id = taxDataProviderId
        and a.name in (
            'AK - KENAI PENINSULA, BOROUGH SALES TAX',
            'AK - KENAI, CITY SALES TAX',
            'AK - SOLDOTNA, CITY SALES TAX',
            'AK - SEWARD, CITY SALES TAX',
            'AK - HOMER, CITY SALES TAX',
            'AK - SELDOVIA, CITY SALES TAX'
        )
        group by r.rule_order, r.start_Date, r.product_category_id, r.rate_Code, r.exempt , r.tax_type, r.is_local
        having count(*) != 6
    ) sub
    where outera.authority_id = outerr.authority_id
    and outera.merchant_id = outerr.merchant_id
    and outera.name in (
        'AK - KENAI PENINSULA, BOROUGH SALES TAX',
        'AK - KENAI, CITY SALES TAX',
        'AK - SOLDOTNA, CITY SALES TAX',
        'AK - SEWARD, CITY SALES TAX',
        'AK - HOMER, CITY SALES TAX',
        'AK - SELDOVIA, CITY SALES TAX'
    )
    and outerr.rule_order = sub.rule_order
    and outerr.start_Date = sub.start_Date
    and outerr.product_category_id = sub.product_category_id
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = outerr.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_150 finished.',runId);
    COMMIT;
END;


 
 
/