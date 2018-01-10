CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_168"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -789;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_168 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT za.primary_key, dataCheckId, runId, SYSDATE
    from ct_zone_authorities za
    where za.authority_name like '%NAVAJO NATION, TRIBAL%'
    AND za.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM ct_zone_authorities za2
        WHERE za.primary_key = za2.primary_key
        and za2.authority_name like '%(NAVAJO NATION)%'
        and za.zone_authority_id != za2.zone_authority_id
        )
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_168 finished.',runId);
    COMMIT;
END;


 
 
/