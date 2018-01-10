CREATE OR REPLACE TRIGGER content_repo."INS_REF_VALUE_TYPES" 
 BEFORE
  INSERT
 ON content_repo.ref_value_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_ref_value_types.nextval;
END;
/