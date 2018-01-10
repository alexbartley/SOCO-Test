CREATE OR REPLACE TRIGGER content_repo."INS_SERVICE_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.service_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_service_revisions.nextval;
END IF;
:new.id := pk_service_revisions.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/