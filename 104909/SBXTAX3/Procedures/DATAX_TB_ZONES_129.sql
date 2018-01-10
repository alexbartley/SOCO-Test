CREATE OR REPLACE PROCEDURE sbxtax3.datax_tb_zones_129
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="129" name="Incorrect International Waters Short Code" >
   dataCheckId NUMBER := -676;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_129 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.name = 'INTERNATIONAL WATERS'
    AND z.merchant_id = taxDataProviderId
    AND NVL(code_2char,'XX') != 'IW'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_129 finished.',runId);
    COMMIT;
END;
 
 
/