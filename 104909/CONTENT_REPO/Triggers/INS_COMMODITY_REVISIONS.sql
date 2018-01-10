CREATE OR REPLACE TRIGGER content_repo."INS_COMMODITY_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.commodity_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_commodity_revisions.nextval;
END IF;
:new.id := pk_commodity_revisions.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/