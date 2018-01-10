CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_APP_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.juris_tax_app_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_JURIS_TAX_APP_REVISIONS.nextval;
END IF;
:new.id := pk_JURIS_TAX_APP_REVISIONS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/