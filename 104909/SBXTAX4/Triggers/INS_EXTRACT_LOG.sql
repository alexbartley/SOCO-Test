CREATE OR REPLACE TRIGGER sbxtax4."INS_EXTRACT_LOG" 
 BEFORE
  INSERT
 ON sbxtax4.extract_log
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
begin
    :new.id := pk_extract_log.nextval;
    :new.queued_date := SYSTIMESTAMP;
END;
/