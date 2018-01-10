CREATE OR REPLACE TRIGGER content_repo."UPD_JURIS_TAX_IMP_TAGS" 
 BEFORE
  UPDATE
 ON content_repo.juris_tax_imposition_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE :new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/