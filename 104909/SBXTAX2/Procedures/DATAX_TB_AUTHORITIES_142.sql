CREATE OR REPLACE PROCEDURE sbxtax2.datax_tb_authorities_142
   ( taxDataProviderID IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="142" name="Food-Beverage Authorities with TOJ value of N">
   dataCheckId NUMBER := -681;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_142 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT sub.authority_id, dataCheckId, runId, SYSDATE
    FROM (
        SELECT a.authority_id
        FROM tb_authorities a, tb_authority_requirements o, tb_authority_types aty
        WHERE a.authority_id = o.authority_id
        AND o.merchant_id = a.merchant_id
        AND a.merchant_id = taxDataProviderID
        AND o.name = 'TOJ'
        AND value = 'N'
        AND aty.authority_type_id = a.authority_type_id
        AND aty.name LIKE '%Food/Beverage'
        minus
        SELECT a.authority_id
        FROM tb_authorities a, tb_authority_requirements o
        WHERE a.authority_id = o.authority_id
        and a.merchant_id = o.merchant_id
        AND a.merchant_id = taxDataProviderID
        AND o.name = 'TOJ'
        AND value = 'N'
        AND exists (
            select 1
            from tb_rates r
            where r.authority_id = a.authority_id
            and r.merchant_id = a.merchant_id
            and r.end_Date is null
            and r.rate_code in ('CU','ST','SU','RS','RU')
            )
        ) sub
    where NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = sub.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_142 finished.',runId);
    COMMIT;
END;
 
 
/