CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONE_AUTH_171"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -793;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_AUTH_171 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT za.zone_authority_id, dataCheckId, runId, SYSDATE
    from ct_zone_authorities za
    join tb_states s on (s.name = za.zone_3_name)
    where za.authority_name like '%STATE%'
    and s.code != substr(za.authority_name,1,2)
    and substr(za.authority_name,1,2) != 'US'
    and nvl(reverse_flag,'N') != 'Y'
    AND za.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.zone_authority_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONE_AUTH_171 finished.',runId);
    COMMIT;
END;


 
 
 
/