CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_172"
   (taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
    --<data_check id="172" name="Zones with no authorities attached or only US authorities attached" >
    dataCheckId NUMBER := -794;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_172 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.zone_id NOT IN (
        Select z.zone_id
        FROM tb_zones z
        JOIN tb_zone_authorities za ON (z.zone_id = za.zone_id)
        JOIN tb_authorities a ON (za.authority_id = a.authority_id)
        WHERE a.name NOT IN ('US - FEDERAL EXCISE TAX', 'US - UNITED STATES EXPORT', 'US - NO TAX STATES')
    )
    AND NVL(z.reverse_flag,'N') = 'Y'
    AND z.terminator_flag = 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = z.zone_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_172 finished.',runId);
    COMMIT;
END;

/*
Author: Kim Ward
Version: 2014.06.19
Created for Jira QAE1508
A zone that is bottom up terminates processing and has the terminates box checked that...
either has no authorities attached
or only has US - FEDERAL EXCISE TAX and/or US - UNITED STATES EXPORT and/or
 US - NO TAX STATES attached (these are the only authorities that begin with "US")
*/


 
 
/