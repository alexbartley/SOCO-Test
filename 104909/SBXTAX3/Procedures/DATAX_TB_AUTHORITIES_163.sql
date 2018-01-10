CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_authorities_163
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="163" name="Authorities with blank ERP">
   dataCheckId NUMBER := -642;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_163 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE ( a.erp_tax_code IS NULL OR TRIM(a.erp_tax_code) = '')
    AND a.merchant_id = taxDataProviderId
    AND a.name not like '%Template%'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_163 finished.',runId);
    COMMIT;
END;
 
 
/