CREATE OR REPLACE TRIGGER content_repo."UPD_CONTACT_USAGES" 
 BEFORE 
 UPDATE
 ON content_repo.CONTACT_USAGES
 FOR EACH ROW 
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE 
:new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/