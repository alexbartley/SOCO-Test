CREATE OR REPLACE TRIGGER content_repo."INS_CALCULATION_METHODS" 
 BEFORE
  INSERT
 ON content_repo.calculation_methods
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_CALCULATION_METHODS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/