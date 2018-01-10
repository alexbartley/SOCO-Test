CREATE OR REPLACE TRIGGER content_repo."INS_TAX_DESCRIPTIONS"
 BEFORE
 INSERT
 ON content_repo.TAX_DESCRIPTIONS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_tax_descriptions.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

-- CRAPP-2195 change
:new.status := 2;
END;
/