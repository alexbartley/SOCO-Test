CREATE OR REPLACE TRIGGER content_repo."INS_JURISDICTION_TAX_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.jurisdiction_tax_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_JURIS_TAX_REVISIONS.nextval;
END IF;
:new.id := pk_JURISDICTION_TAX_REVISIONS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/