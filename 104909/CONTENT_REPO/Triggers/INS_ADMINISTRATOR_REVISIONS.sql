CREATE OR REPLACE TRIGGER content_repo."INS_ADMINISTRATOR_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.administrator_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_ADMINISTRATOR_REVISIONS.nextval;
END IF;
:new.id := pk_ADMINISTRATOR_REVISIONS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/