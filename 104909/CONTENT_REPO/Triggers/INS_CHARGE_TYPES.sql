CREATE OR REPLACE TRIGGER content_repo.ins_charge_types
 BEFORE
  INSERT
 ON content_repo.charge_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_charge_types.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/