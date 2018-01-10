CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONE_AUTH_100"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -730;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_AUTH_100 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT za.zone_authority_id, dataCheckId, runId, SYSDATE
    FROM ct_zone_Authorities za, tb_states s
    WHERE SUBSTR(za.authority_name,1,2) != s.code
    AND s.name = za.zone_3_name
    AND authority_name NOT LIKE 'US%'
    AND za.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.zone_authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_AUTH_100 finished.',runId);
    COMMIT;
END;


 
 
/