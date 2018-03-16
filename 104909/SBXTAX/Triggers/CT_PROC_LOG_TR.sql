CREATE OR REPLACE TRIGGER sbxtax."CT_PROC_LOG_TR" 
 BEFORE
  INSERT
 ON sbxtax.ct_proc_log
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT ct_proc_log_seq.NEXTVAL INTO :new.log_id FROM dual;
  END;
/