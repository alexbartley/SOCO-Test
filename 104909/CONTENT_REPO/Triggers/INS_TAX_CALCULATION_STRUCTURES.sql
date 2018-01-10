CREATE OR REPLACE TRIGGER content_repo."INS_TAX_CALCULATION_STRUCTURES" 
 BEFORE
  INSERT
 ON content_repo.tax_calculation_structures
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_TAX_CALCULATION_STRUCTURES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/