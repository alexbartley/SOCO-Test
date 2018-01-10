CREATE OR REPLACE TRIGGER content_repo."UPD_PACKAGE_TAG_TABLE_MAPPING" 
 BEFORE
  UPDATE
 ON content_repo.package_tag_table_mapping
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE 
:new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/