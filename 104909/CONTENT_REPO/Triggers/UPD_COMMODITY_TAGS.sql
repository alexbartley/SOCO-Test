CREATE OR REPLACE TRIGGER content_repo."UPD_COMMODITY_TAGS" 
 BEFORE 
 UPDATE
 ON content_repo.COMMODITY_TAGS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE :new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/