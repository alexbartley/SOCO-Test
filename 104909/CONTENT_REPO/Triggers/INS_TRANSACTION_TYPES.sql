CREATE OR REPLACE TRIGGER content_repo."INS_TRANSACTION_TYPES" 
 BEFORE
  INSERT
 ON content_repo.transaction_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_TRANSACTION_TYPES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/