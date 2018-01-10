CREATE OR REPLACE PROCEDURE content_repo.gis_etl_p (pID IN NUMBER, pState IN VARCHAR2, pPart IN VARCHAR2, pAction IN NUMBER, pUser IN NUMBER) IS
  PRAGMA autonomous_transaction;
BEGIN

    IF pAction = 0 THEN     -- Create starting record
        EXECUTE IMMEDIATE 'INSERT INTO gis_etl_process_log (process_id, state_code, etl_process, start_date, entered_by) VALUES(:pID, :pState, :pPart, SYSTIMESTAMP, :pUser)'
        USING pID, pState, pPart, pUser;

    ELSIF pAction = 1 THEN  -- Update ending time
        UPDATE gis_etl_process_log
            SET end_date = SYSTIMESTAMP
        WHERE   process_id = pID
                AND etl_process = pPart
                AND end_date IS NULL;

    ELSIF pAction = 3 THEN -- Create Starting/Ending record
        EXECUTE IMMEDIATE 'INSERT INTO gis_etl_process_log (process_id, state_code, etl_process, start_date, end_date, entered_by) '||
                          'VALUES(:pID, :pState, :pPart, SYSTIMESTAMP, SYSTIMESTAMP, :pUser)'
        USING pID, pState, pPart, pUser;
    END IF;
    COMMIT;
END;
 
/