CREATE OR REPLACE TRIGGER sbxtax2."DT_AUTHORITIES_BEFORE_UPDATE"
 BEFORE 
 INSERT OR UPDATE
 ON sbxtax2.TB_AUTHORITIES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
  :NEW.AUTHORITY_CATEGORY := content_repo.fnNLSConvert(pfield=> :NEW.AUTHORITY_CATEGORY);
  :NEW.OFFICIAL_NAME := content_repo.fnNLSConvert(pfield=> :NEW.OFFICIAL_NAME);
  :NEW.NAME := content_repo.fnNLSConvert(pfield=> :NEW.NAME);
  :NEW.DESCRIPTION := content_repo.fnNLSConvert(pfield=> :NEW.DESCRIPTION);
    
  /* old
  :NEW.AUTHORITY_CATEGORY := trim(:NEW.AUTHORITY_CATEGORY);
  :NEW.AUTHORITY_CATEGORY := replace(:NEW.AUTHORITY_CATEGORY,'  ',' ');
  :NEW.OFFICIAL_NAME := trim(:NEW.OFFICIAL_NAME);
  :NEW.NAME := trim(:NEW.NAME);
  */
END;
/