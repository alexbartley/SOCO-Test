CREATE OR REPLACE TRIGGER content_repo."UPD_JURIS_TAX_APP_REVISIONS" 
 BEFORE
 UPDATE
 ON content_repo.JURIS_TAX_APP_REVISIONS
 FOR EACH ROW
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE
:new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/