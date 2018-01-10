CREATE OR REPLACE TRIGGER content_repo."INS_GEO_UNIQUE_CHG_CITS"
 BEFORE
 INSERT
 ON content_repo.GEO_UNIQUE_AREA_CHG_CITS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_geo_unique_chg_cits.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/