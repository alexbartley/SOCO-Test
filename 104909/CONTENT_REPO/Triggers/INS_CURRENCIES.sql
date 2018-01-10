CREATE OR REPLACE TRIGGER content_repo."INS_CURRENCIES" 
 BEFORE
  INSERT
 ON content_repo.currencies
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_currencies.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/