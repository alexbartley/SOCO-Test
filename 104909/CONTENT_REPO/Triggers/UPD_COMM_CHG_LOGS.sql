CREATE OR REPLACE TRIGGER content_repo."UPD_COMM_CHG_LOGS" 
 BEFORE 
 UPDATE
 ON content_repo.COMM_CHG_LOGS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
IF UPDATING('STATUS') THEN
    :new.status_modified_Date := SYSTIMESTAMP;
    EXECUTE IMMEDIATE 'UPDATE '||:old.table_name||' SET status = '||:new.status||' WHERE id = '||:old.primary_key;
    UPDATE commodity_revisions
    SET status = :new.status
    WHERE id = :old.rid;
END IF;

END;
/