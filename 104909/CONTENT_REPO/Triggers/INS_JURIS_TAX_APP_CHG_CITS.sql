CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_APP_CHG_CITS" 
 BEFORE
  INSERT
 ON content_repo.juris_tax_app_chg_cits
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_tax_app_chg_cits.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/