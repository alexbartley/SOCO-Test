CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_AUTHORITIES_160"
   ( runId IN OUT NUMBER)
   IS
   --<data_check id="160" name="Netweaver Regmask Bracket issue">
   dataCheckId NUMBER := -716;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_160 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a, tb_merchants m
    WHERE registration_mask LIKE '%{%'
    AND a.merchant_id = m.merchant_id
    and m.name like 'Sabrix%Tax Data'
    AND length(a.registration_mask)-length(replace(a.registration_mask,'{','')) > 10
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = a.authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_AUTHORITIES_160 finished.',runId);
    COMMIT;
END;


 
 
 
/