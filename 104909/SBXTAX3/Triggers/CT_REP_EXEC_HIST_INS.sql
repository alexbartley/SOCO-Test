CREATE OR REPLACE TRIGGER sbxtax3."CT_REP_EXEC_HIST_INS" 
 BEFORE
  INSERT
 ON sbxtax3.ct_report_exec_history
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT ct_rep_exec_seq.NEXTVAL INTO :new.report_exec_id FROM dual;
  END;
/