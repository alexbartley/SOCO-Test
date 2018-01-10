CREATE OR REPLACE TRIGGER content_repo."INS_REF_GROUP_TAGS" 
 BEFORE
  INSERT
 ON content_repo.ref_group_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_reference_group_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/