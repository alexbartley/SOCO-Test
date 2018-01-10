CREATE OR REPLACE TRIGGER content_repo."INS_GEO_POLY_CHG_CITS"
 BEFORE
 INSERT
 ON content_repo.GEO_POLY_REF_CHG_CITS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_geo_poly_chg_cits.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/