CREATE OR REPLACE TRIGGER content_repo."UPD_REF_GRP_CHG_LOGS" 
 BEFORE
 UPDATE
 ON content_repo.ref_grp_chg_logs
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
-- Why was this one missing on 10/10/2014?
IF UPDATING('STATUS') THEN
    :new.status_modified_Date := SYSTIMESTAMP;
    EXECUTE IMMEDIATE 'UPDATE '||:old.table_name||' SET status = '||:new.status||' WHERE id = '||:old.primary_key;
    UPDATE ref_group_revisions
    SET status = :new.status
    WHERE id = :old.rid;
END IF;

END;
/