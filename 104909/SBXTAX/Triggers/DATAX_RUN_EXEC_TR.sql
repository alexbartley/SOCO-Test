CREATE OR REPLACE TRIGGER sbxtax."DATAX_RUN_EXEC_TR" 
 BEFORE
  INSERT
 ON sbxtax.datax_run_executions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_run_exec_seq.NEXTVAL INTO :new.run_execution_id FROM dual;
  END;
/