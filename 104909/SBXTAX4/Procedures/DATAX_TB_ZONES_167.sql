CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_ZONES_167"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   dataCheckId NUMBER := -788;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_167 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT za.primary_key, dataCheckId, runId, SYSDATE
    FROM ct_zone_authorities za
    where za.authority_name like '%NAVAJO NATION, TRIBAL%'
    and (nvl(za.reverse_flag, 'N') != 'Y' or nvl(za.terminator_flag, 'N') != 'Y')
    AND za.merchant_id = taxDataProviderId
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_167 finished.',runId);
    COMMIT;
END;


 
 
 
/