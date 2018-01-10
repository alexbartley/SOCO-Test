CREATE OR REPLACE TRIGGER content_repo."INS_LOGICAL_QUALIFIERS" 
 BEFORE
  INSERT
 ON content_repo.logical_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_logical_qualifiers.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/