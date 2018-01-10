CREATE OR REPLACE TRIGGER content_repo."INS_PACKAGE_TAG_COL_MAPPING" 
 BEFORE
  INSERT
 ON content_repo.package_tag_column_mapping
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_PACKAGE_TAG_COLUMN_MAPPING.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/