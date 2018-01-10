CREATE OR REPLACE TRIGGER sbxtax2."DT_PRODUCT_CATEGORY_CHR"
 BEFORE 
 INSERT OR UPDATE
 ON sbxtax2.TB_PRODUCT_CATEGORIES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
  -- Moved from ins/upd/del trigger as a test 7/25
  :NEW.NAME := content_repo.fnNLSConvert(pfield=> :NEW.NAME);
  :NEW.DESCRIPTION := content_repo.fnNLSConvert(pfield=> :NEW.DESCRIPTION);
END;
/