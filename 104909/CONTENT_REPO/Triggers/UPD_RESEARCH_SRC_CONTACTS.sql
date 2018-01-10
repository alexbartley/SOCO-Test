CREATE OR REPLACE TRIGGER content_repo."UPD_RESEARCH_SRC_CONTACTS" 
 BEFORE 
 UPDATE
 ON content_repo.RESEARCH_SOURCE_CONTACTS
 FOR EACH ROW 
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE 
:new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/