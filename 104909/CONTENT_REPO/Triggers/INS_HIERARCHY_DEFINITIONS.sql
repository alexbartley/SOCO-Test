CREATE OR REPLACE TRIGGER content_repo."INS_HIERARCHY_DEFINITIONS" 
 BEFORE
  INSERT
 ON content_repo.hierarchy_definitions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_HIERARCHY_DEFINITIONS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/