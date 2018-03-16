CREATE OR REPLACE TRIGGER sbxtax2."CT_PROC_LOG_TR" 
 BEFORE
  INSERT
 ON sbxtax2.ct_proc_log
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT ct_proc_log_seq.NEXTVAL INTO :new.log_id FROM dual;
  END;
/