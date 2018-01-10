CREATE OR REPLACE TRIGGER content_repo."INS_COMMODITY_TAGS" 
 BEFORE
  INSERT
 ON content_repo.commodity_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_commodity_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/