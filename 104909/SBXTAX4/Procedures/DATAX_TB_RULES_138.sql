CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_138"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="138" name="VI Non-exempt Rules with Tax Base not populated">
   dataCheckId NUMBER := -686;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_138 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_rules r
    WHERE r.merchant_id = taxDataProviderId
    AND a.name LIKE 'VI - %'
    AND NVL(r.basis_percent,1) !=1.05
    AND a.merchant_id = r.merchant_id
    AND a.authority_id = r.authority_id
    AND NVL(r.exempt,'N') = 'N'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = r.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_138 finished.',runId);
    COMMIT;
END;


 
 
 
/