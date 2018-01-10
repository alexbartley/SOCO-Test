CREATE OR REPLACE TRIGGER content_repo.upd_juris_type_tags
 BEFORE
  UPDATE
 ON content_repo.juris_type_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:old.status = :new.status) THEN
:new.entered_date := SYSTIMESTAMP;
ELSE :new.status_modified_date := SYSTIMESTAMP;
END IF;
END;
/