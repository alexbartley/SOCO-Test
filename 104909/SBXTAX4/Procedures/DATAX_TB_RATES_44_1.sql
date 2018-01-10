CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RATES_44_1"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="44.1" name="Rates without 1-1-2000 Instances" >
   dataCheckId NUMBER := -656;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_44_1 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT r.rate_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rates r, tb_authority_types aty
    WHERE a.authority_id = r.authority_id
    AND r.merchant_id = taxDataProviderId
    AND a.authority_type_id = aty.authority_type_id
    AND aty.name NOT LIKE UPPER('%FOOD/BEVERAGE%')
    AND (
        r.rate_code IN ('CU', 'NL', 'ST', 'SU', 'RS', 'RU')
        OR
        (rate_code IN ('MMCU', 'MMST', 'MMSU') AND a.name LIKE 'AL%')
        )
    AND NOT EXISTS(
        SELECT 1
        FROM tb_rates
        WHERE rate_code = r.rate_code
        AND authority_id = r.authority_id
        AND start_date = TO_DATE('2000.01.01', 'YYYY.MM.DD')
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rate_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RATES_44_1 finished.',runId);
    COMMIT;
END;


 
 
 
/