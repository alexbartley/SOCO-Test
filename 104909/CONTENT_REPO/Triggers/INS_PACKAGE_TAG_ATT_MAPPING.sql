CREATE OR REPLACE TRIGGER content_repo."INS_PACKAGE_TAG_ATT_MAPPING" 
 BEFORE
  INSERT
 ON content_repo.package_tag_attribute_mapping
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_PACKAGE_TAG_ATT_MAPPING.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/