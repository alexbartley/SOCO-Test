CREATE OR REPLACE TRIGGER content_repo."INS_CHANGE_REASONS" 
 BEFORE
  INSERT
 ON content_repo.change_reasons
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_change_reasons.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/