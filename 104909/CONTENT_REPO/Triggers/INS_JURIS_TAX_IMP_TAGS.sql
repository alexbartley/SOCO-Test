CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_IMP_TAGS" 
 BEFORE
  INSERT
 ON content_repo.juris_tax_imposition_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_juris_tax_imposition_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/