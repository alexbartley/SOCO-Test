CREATE OR REPLACE TRIGGER content_repo."INS_TAX_STRUCTURE_TYPES" 
 BEFORE
  INSERT
 ON content_repo.tax_structure_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_TAX_STRUCTURE_TYPES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/