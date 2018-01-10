CREATE OR REPLACE TRIGGER content_repo."INS_GEO_LOAD_LOG" 
 BEFORE
  INSERT
 ON content_repo.geo_load_log
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    :new.id := pk_geo_load_log.nextval;
    :new.start_time := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;
END;
/