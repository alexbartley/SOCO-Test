CREATE OR REPLACE TRIGGER content_repo."INS_TAX_TYPES"
 BEFORE
  INSERT
 ON content_repo.tax_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/