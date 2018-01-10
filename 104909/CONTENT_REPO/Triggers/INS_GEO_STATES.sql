CREATE OR REPLACE TRIGGER content_repo.ins_geo_states
 BEFORE
  INSERT
 ON content_repo.geo_states
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

    :new.id := pk_geo_states.nextval;
    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;

END;
/