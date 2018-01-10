CREATE OR REPLACE TRIGGER content_repo."INS_ASSIGNMENT_TYPES" 
 BEFORE
  INSERT
 ON content_repo.assignment_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_assignment_types.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/