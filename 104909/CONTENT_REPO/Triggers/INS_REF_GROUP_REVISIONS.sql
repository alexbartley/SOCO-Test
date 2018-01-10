CREATE OR REPLACE TRIGGER content_repo."INS_REF_GROUP_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.ref_group_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_ref_group_revisions.nextval;
END IF;
:new.id := pk_ref_group_revisions.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/