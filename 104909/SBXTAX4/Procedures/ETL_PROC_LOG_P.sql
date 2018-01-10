CREATE OR REPLACE PROCEDURE sbxtax4.etl_proc_log_p (pAction IN VARCHAR2, pMsg IN VARCHAR2, pEntity IN VARCHAR2, pNKID IN NUMBER, pRID IN NUMBER) IS
  PRAGMA autonomous_transaction;
BEGIN

    EXECUTE IMMEDIATE 'INSERT INTO etl_proc_log (action, message, entity, nkid, rid) VALUES(:pAction, :pMsg, :pEntity, :pNKID, :pRID)'
    USING pAction, pMsg, pEntity, pNKID, pRID;

    COMMIT;
END;
 
/