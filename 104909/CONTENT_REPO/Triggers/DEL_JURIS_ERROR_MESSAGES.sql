CREATE OR REPLACE TRIGGER content_repo.DEL_JURIS_ERROR_MESSAGES
 AFTER
 DELETE
 ON content_repo.JURIS_ERROR_MESSAGES 
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
    DELETE FROM juris_chg_logs
     WHERE rid = :old.rid and primary_key = :old.id
       AND table_name = 'JURIS_ERROR_MESSAGES';
END;
/