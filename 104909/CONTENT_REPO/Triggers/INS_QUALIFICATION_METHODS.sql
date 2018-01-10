CREATE OR REPLACE TRIGGER content_repo."INS_QUALIFICATION_METHODS" 
 BEFORE
  INSERT
 ON content_repo.qualification_methods
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_qualification_methods.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/