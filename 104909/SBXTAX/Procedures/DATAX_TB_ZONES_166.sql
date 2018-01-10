CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_ZONES_166"
   (runId IN OUT NUMBER)
   IS
    --<data_check id="166" name="New IL-MO plus4s that need to be handled in the F Snapshot" >
    --If results appear, this data check needs to be updated(hard-coding the plus4's) with those results
    --and the Snapshot script "buildZoneAuthorityTable.sql" needs to be updated with the new results as well.
    --This list in this data check and the list in buildZoneAuthorityTable.sql must always match
    dataCheckId NUMBER := -790;
BEGIN

    dbms_output.put_line('Entered into 166 data check');
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_166 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT DISTINCT za.primary_key, dataCheckId, runId, SYSDATE
    from ct_zone_authorities za
    where zone_3_name = 'MISSOURI'
    and authority_name like 'IL%'
    and zone_7_name not in (
        '9100-9100',
        '9102-9102',
        '9106-9106',
        '9115-9115',
        '9122-9123',
        '9126-9127',
        '9130-9130',
        '9136-9137',
        '9178-9178',
        '9328-9329',
        '9335-9335')
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = za.primary_key
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_ZONES_166 finished.',runId);
    COMMIT;
END;




 
/