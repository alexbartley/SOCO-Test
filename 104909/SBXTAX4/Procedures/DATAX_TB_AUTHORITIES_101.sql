CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_101"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="101" name="Duplicate ERP Tax Codes" >
   dataCheckId NUMBER := -640;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_101 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.merchant_id = taxDataProviderId
    AND is_template = 'N'
    AND a.erp_tax_code IN (
        SELECT erp_tax_code
        FROM tb_authorities a2
        WHERE a2.merchant_id = a.merchant_id
        AND NOT ((a2.name = 'Argentina' or a2.name = 'Argentina Percepcion' or a2.name = 'Argentina Surtax') and a2.erp_tax_Code = 'ARIVA')
        AND NOT (a2.name IN ('Alberta','No VAT') and a2.erp_tax_code = 'XVAT')
        GROUP BY erp_tax_code
        HAVING COUNT(*) > 1
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_101 finished.',runId);
    COMMIT;
END;


 
 
 
/