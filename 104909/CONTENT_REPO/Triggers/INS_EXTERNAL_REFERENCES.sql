CREATE OR REPLACE TRIGGER content_repo."INS_EXTERNAL_REFERENCES" 
 BEFORE 
 INSERT
 ON content_repo.External_References
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
IF (:new.id IS NULL) THEN
    :new.id := pk_External_References.nextval;
END IF;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/