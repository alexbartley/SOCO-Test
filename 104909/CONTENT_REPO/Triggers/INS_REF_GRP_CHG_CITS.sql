CREATE OR REPLACE TRIGGER content_repo."INS_REF_GRP_CHG_CITS" 
 BEFORE
  INSERT
 ON content_repo.ref_grp_chg_cits
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_ref_grp_chg_cits.nextval;
:new.entered_Date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/