CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_AUTHORITIES_51"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id = "51" name="Rental Authorities with Non-rental Rate Codes" >
   dataCheckId NUMBER := -777;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_51 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND a.name like '%RENTAL%'
    AND NOT EXISTS (
        SELECT 1
        FROM tb_rates rs, tb_rates ru
        WHERE rs.rate_Code = 'RS'
        AND ru.rate_code = 'RU'
        AND rs.authority_id = a.authority_id
        AND rs.merchant_id = a.merchant_id
        AND ru.authority_id = rs.authority_id
        AND ru.merchant_id = rs.merchant_id
        AND ru.end_date IS NULL
        AND rs.end_Date IS NULL
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_51 finished.',runId);
    COMMIT;
END;


 
 
/