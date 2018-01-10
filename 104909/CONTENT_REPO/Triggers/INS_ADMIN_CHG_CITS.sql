CREATE OR REPLACE TRIGGER content_repo."INS_ADMIN_CHG_CITS" 
 BEFORE
  INSERT
 ON content_repo.admin_chg_cits
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_admin_chg_cits.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/