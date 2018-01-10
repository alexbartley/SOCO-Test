CREATE OR REPLACE TRIGGER content_repo.ins_geo_poly_issue_log
 BEFORE
  INSERT
 ON content_repo.geo_poly_issue_log
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

IF (:new.id IS NULL) THEN
    :new.id := pk_geo_poly_issue_log.nextval;
END IF;

:new.entered_date := SYSTIMESTAMP;

END;
/