CREATE OR REPLACE TRIGGER content_repo."UPD_CHANGE_REASONS" 
 BEFORE
  UPDATE
 ON content_repo.change_reasons
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE 
:new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/