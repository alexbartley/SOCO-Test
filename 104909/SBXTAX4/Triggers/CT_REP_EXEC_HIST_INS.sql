CREATE OR REPLACE TRIGGER sbxtax4."CT_REP_EXEC_HIST_INS" 
 BEFORE 
 INSERT
 ON sbxtax4.CT_REPORT_EXEC_HISTORY
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
      SELECT ct_rep_exec_seq.NEXTVAL INTO :new.report_exec_id FROM dual;
  END;
/